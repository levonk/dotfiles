#!/usr/bin/env bash

# template-sync.bash — Generate template include files from a source directory
#
# This script synchronizes files from a source directory to one or more destination
# directories, creating template files that include the source files. It offers
# various options for controlling the directory structure, template type, and
# filename transformations.

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P)

# Defaults; allow overrides
CHEZMOI_ROOT_DEFAULT="$REPO_ROOT/home/current"
CHEZMOI_ROOT="${CHEZMOI_ROOT:-$CHEZMOI_ROOT_DEFAULT}"
CHEZMOI_TEMPLATES_ROOT="${CHEZMOI_TEMPLATES_ROOT:-$CHEZMOI_ROOT/.chezmoitemplates}"


DRY_RUN=0
VERBOSE=0
DELETE_STALE=0
FORCE=0
QUIET=0

# Parameterizable options
# Parameterizable options for single run
SRC_DIR_REL="dot_config/ai/workflows"
DEST_DIRS_REL=()
DEST_TEMPLATE_TYPE="go"
TREE_HANDLING="flatten"
TRANSFORM="none"

# Config file options
CONFIG_FILE=""
JOBS_TO_RUN=""

log() { printf '%s\n' "$*"; }
vlog() { if [ "$VERBOSE" -eq 1 ]; then printf '%s\n' "$*"; fi; }
warn() { [ "$QUIET" -eq 1 ] || printf 'warn: %s\n' "$*" >&2; }
err() { printf 'error: %s\n' "$*" >&2; }

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

This script can be run in two modes:
1. Single run mode, using command-line arguments.
2. Batch mode, using a JSONC configuration file to define multiple jobs.

Options:
  --config <file>         Path to a JSONC config file for batch mode.
  --jobs <name1,name2>    Comma-separated list of job names to run from config (default: all).

Single-run options (ignored if --config is used):
  --src <dir>             Source directory relative to chezmoi templates root.
                          (default: $SRC_DIR_REL)
  --dest <dir>            Destination directory relative to chezmoi root. Can be used multiple times.
                          (default: 'dot_codeium/windsurf/global_workflows' and 'dot_codeium/windsurf-next/global_workflows')
  --dest-template-type    Template type for destination files (go, raw-include).
                          (default: $DEST_TEMPLATE_TYPE)
  --tree-handling <mode>  How to handle directory structure (flatten, tree, top-only).
                          (default: $TREE_HANDLING)
  --transform <mode>      Filename transformation mode (none, kebab).
                          (default: $TRANSFORM)

  --delete-stale          Delete destination files if their source include is missing.
  --force                 Overwrite existing files, even if they have conflicts.
  --dry-run               Print what would be done without making changes.
  --verbose, -v           Enable verbose logging.
  --quiet                 Suppress warning messages.
  -h, --help              Show this help message.

Env overrides:
  CHEZMOI_ROOT (default: $CHEZMOI_ROOT_DEFAULT)
  CHEZMOI_TEMPLATES_ROOT (default: $CHEZMOI_ROOT/.chezmoitemplates)
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --config) CONFIG_FILE="$2"; shift ;;
    --jobs) JOBS_TO_RUN="$2"; shift ;;
    --src) SRC_DIR_REL="$2"; shift ;;
    --dest) DEST_DIRS_REL+=("$2"); shift ;;
    --dest-template-type) DEST_TEMPLATE_TYPE="$2"; shift ;;
    --tree-handling) TREE_HANDLING="$2"; shift ;;
    --transform) TRANSFORM="$2"; shift ;;
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --delete-stale) DELETE_STALE=1 ;;
    --force) FORCE=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown arg: $1"; usage; exit 2 ;;
  esac
  shift
done

ensure_dir() {
  local d="$1"
  if [ "$DRY_RUN" -eq 1 ]; then
    vlog "Would mkdir -p: $d"
  else
    mkdir -p -- "$d"
  fi
}

# If file is a single include or includeTemplate line, print target path and return 0; else return 1
extract_include_target_from_file() {
  local f="$1"
  [ -f "$f" ] || return 1
  # Normalize CRLF, trim whitespace per line, drop empty lines
  local lines
  lines=$(tr -d '\r' <"$f" | sed -E 's/^\s+//; s/\s+$//' | sed '/^$/d') || return 1
  # exactly one non-empty line
  if [ "$(printf '%s\n' "$lines" | wc -l | tr -d ' ')" != "1" ]; then
    return 1
  fi
  local line
  line=$(printf '%s' "$lines")
  if printf '%s' "$line" | grep -Eq '^\{\{\s*(includeTemplate\s+"[^"]+"\s+\.|include\s+"[^"]+")\s*\}\}$'; then
    printf '%s\n' "$line" | sed -E 's/^\{\{\s*(includeTemplate|include)\s+"([^"]+)".*$/\2/'
    return 0
  fi
  return 1
}

write_include_file() {
  local dst_file="$1"; shift
  local include_path="$1"; shift
  local template_type="$1"; shift

  ensure_dir "$(dirname -- "$dst_file")"

  local content=""
  case "$template_type" in
    go) content=$(printf '{{ includeTemplate "%s" . }}\n' "$include_path") ;;
    raw-include) content=$(printf '{{ include "%s" }}\n' "$include_path") ;;
    *) err "unknown dest-template-type: $template_type"; return 1 ;;
  esac

  if [ "$DRY_RUN" -eq 1 ]; then
    log "Would write: $dst_file <- $content"
  else
    printf '%s' "$content" >"$dst_file"
  fi
}

is_git_ignored() {
  local abs="$1"
  # Use repo root for git context; ignore errors if not a git repo
  git -C "$REPO_ROOT" check-ignore -q -- "$abs" 2>/dev/null
}

gather_sources() {
  local root="$1"
  [ -d "$root" ] || { err "missing source root: $root"; return 2; }
  local f
  while IFS= read -r -d '' f; do
    if is_git_ignored "$f"; then
      vlog "Ignored by .gitignore: $f"
      continue
    fi
    printf '%s\0' "$f"
  done < <(find "$root" -type f -name '*.md' -print0)
}

process_one_file() {
  local src_root="$1"; shift
  local dst_root="$1"; shift
  local tree_handling="$1"; shift
  local src_file="$1"; shift
  local src_dir_rel="$1"; shift
  local dest_template_type="$1"; shift
  local transform="$1"; shift

  local rel
  rel="${src_file#"$src_root"/}"

  if [ "$tree_handling" = "top-only" ] && [ "$(dirname -- "$rel")" != "." ]; then
    vlog "Skipping file in subdirectory for top-only mode: $rel"
    return 0
  fi

  local rel_no_ext="${rel%.md}"
  local base
  base="$(basename -- "$rel_no_ext")"
  local dir_rel
  dir_rel="$(dirname -- "$rel_no_ext")"
  [ "$dir_rel" = "." ] && dir_rel=""

  local final_base="$base"
  if [ "$transform" = "kebab" ]; then
    final_base=$(echo "$base" | sed -r 's/([a-z0-9])([A-Z])/\1-\2/g' | tr '[:upper:]' '[:lower:]' | tr '_ ' '-')
  fi

  local include_path="$src_dir_rel/$rel"

  local candidate_dst
  case "$tree_handling" in
    flatten) candidate_dst="$dst_root/$final_base.md.tmpl" ;;
    tree) candidate_dst="$dst_root/$rel_no_ext.md.tmpl" ;;
    top-only) candidate_dst="$dst_root/$final_base.md.tmpl" ;;
    *) err "unknown tree-handling: $tree_handling"; return 1 ;;
  esac

  ensure_dir "$dst_root"

  if [ -f "$candidate_dst" ]; then
    local existing_target=""
    if existing_target=$(extract_include_target_from_file "$candidate_dst" 2>/dev/null); then
      if [ "$existing_target" = "$include_path" ]; then
        vlog "Up-to-date: $candidate_dst includes $include_path"
        return 0
      fi
      if [ "$tree_handling" = "flatten" ]; then
        local prefix=""
        if [ -n "$dir_rel" ]; then
          prefix="$(printf '%s' "$dir_rel" | tr '/ ' '__')_"
        fi
        local final_dst="$dst_root/${prefix}${final_base}.md.tmpl"
        warn "flatten conflict: existing=$candidate_dst includes=$existing_target; attempted=$include_path; writing=$final_dst"

        if [ -f "$final_dst" ]; then
          local existing2=""
          if existing2=$(extract_include_target_from_file "$final_dst" 2>/dev/null); then
            if [ "$existing2" = "$include_path" ]; then
              vlog "Disambiguated already correct: $final_dst"
              return 0
            else
              if [ "$FORCE" -eq 1 ]; then
                write_include_file "$final_dst" "$include_path" "$dest_template_type"
                return 0
              fi
              warn "disambiguated exists with different include; skip (use --force): $final_dst includes=$existing2 attempted=$include_path"
              return 0
            fi
          else
            if [ "$FORCE" -eq 1 ]; then
              write_include_file "$final_dst" "$include_path" "$dest_template_type"
              return 0
            fi
            warn "disambiguated path not single-line include; skip (use --force): $final_dst"
            return 0
          fi
        else
          write_include_file "$final_dst" "$include_path" "$dest_template_type"
          return 0
        fi
      else # not flatten
        if [ "$FORCE" -eq 1 ]; then
          warn "overwrite: $candidate_dst includes=$existing_target -> $include_path"
          write_include_file "$candidate_dst" "$include_path" "$dest_template_type"
          return 0
        fi
        warn "existing file includes different target; skip (use --force): $candidate_dst includes=$existing_target attempted=$include_path"
        return 0
      fi
    else # not an include file
      if [ "$FORCE" -eq 1 ]; then
        warn "overwrite non-include file: $candidate_dst"
        write_include_file "$candidate_dst" "$include_path" "$dest_template_type"
        return 0
      fi
      warn "existing file not single-line include; skip (use --force): $candidate_dst"
      return 0
    fi
  else # destination doesn't exist
    write_include_file "$candidate_dst" "$include_path" "$dest_template_type"
  fi
}

delete_stale_in_destination() {
  local dst_root="$1"
  [ -d "$dst_root" ] || return 0
  local f
  while IFS= read -r -d '' f; do
    local inc
    if inc=$(extract_include_target_from_file "$f" 2>/dev/null); then
      local target_abs="$CHEZMOI_TEMPLATES_ROOT/$inc"
      if [ ! -f "$target_abs" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
          log "Would delete stale: $f (missing source: $target_abs)"
        else
          rm -f -- "$f"
          vlog "Deleted stale: $f"
        fi
      fi
    fi
  done < <(find "$dst_root" -type f -name '*.md.tmpl' -print0)
}

run_sync_operation() {
  local src_dir_rel="$1"; shift
  local dest_dirs_rel_str="$1"; shift
  local tree_handling="$1"; shift
  local dest_template_type="$1"; shift
  local transform="$1"; shift
  local delete_stale_flag="$1"; shift

  local src_root="$CHEZMOI_TEMPLATES_ROOT/$src_dir_rel"
  if [ ! -d "$src_root" ]; then
    err "Source directory missing for job: $src_root"; return 1
  fi

  vlog "Running sync operation..."
  vlog "  Source: $src_dir_rel"
  vlog "  Destinations: $dest_dirs_rel_str"
  vlog "  Tree Handling: $tree_handling"
  vlog "  Template Type: $dest_template_type"
  vlog "  Transform: $transform"
  vlog "  Delete Stale: $delete_stale_flag"

  local dest_rel
  # Read string into array
  local dest_dirs_rel
  read -r -a dest_dirs_rel <<< "$dest_dirs_rel_str"

  for dest_rel in "${dest_dirs_rel[@]}"; do
    local dest_abs="$CHEZMOI_ROOT/$dest_rel"
    vlog "  Processing destination (rel): $dest_rel -> (abs): $dest_abs"
    ensure_dir "$dest_abs"
    while IFS= read -r -d '' s; do
      process_one_file "$src_root" "$dest_abs" "$tree_handling" "$s" "$src_dir_rel" "$dest_template_type" "$transform"
    done < <(gather_sources "$src_root")
    if [ "$delete_stale_flag" -eq 1 ]; then
      delete_stale_in_destination "$dest_abs"
    fi
  done
}

run_single_job() {
  if [ ${#DEST_DIRS_REL[@]} -eq 0 ]; then
    DEST_DIRS_REL=(
      "dot_codeium/windsurf/global_workflows"
      "dot_codeium/windsurf-next/global_workflows"
    )
  fi

  # Convert array to space-separated string for passing
  local dest_dirs_str="${DEST_DIRS_REL[*]}"
  run_sync_operation "$SRC_DIR_REL" "$dest_dirs_str" "$TREE_HANDLING" "$DEST_TEMPLATE_TYPE" "$TRANSFORM" "$DELETE_STALE"
}

run_batch_job() {
  if ! command -v jq &>/dev/null; then
    err "jq is not installed, but it's required for --config mode."
    exit 1
  fi
  if [ ! -f "$CONFIG_FILE" ]; then
    err "Config file not found: $CONFIG_FILE"; exit 1
  fi

  local jobs_filter="."
  if [ -n "$JOBS_TO_RUN" ]; then
    jobs_filter=$(printf '%s' "$JOBS_TO_RUN" | tr ',' '\n' | sed 's/.*/.name=="&"/' | paste -sd ' or ')
    jobs_filter="select($jobs_filter)"
  fi

  # Strip comments and process with jq
  sed 's|//.*||' "$CONFIG_FILE" | jq -c ".[] | $jobs_filter" | while IFS= read -r job_json; do
    local name
    name=$(jq -r '.name // "unnamed"' <<<"$job_json")
    vlog "--- Starting job: $name ---"

    local src dest tree_handling template_type transform delete_stale
    src=$(jq -r '.src' <<<"$job_json")
    dest=$(jq -r '.dest | join(" ")' <<<"$job_json")
    tree_handling=$(jq -r '.tree_handling // "flatten"' <<<"$job_json")
    template_type=$(jq -r '.dest_template_type // "go"' <<<"$job_json")
    transform=$(jq -r '.transform // "none"' <<<"$job_json")
    delete_stale=$(jq -r '.delete_stale // false' <<<"$job_json")
    local delete_stale_flag=0
    [ "$delete_stale" = "true" ] && delete_stale_flag=1

    if [ -z "$src" ] || [ "$src" = "null" ]; then
      warn "Skipping job '$name' due to missing 'src' attribute."
      continue
    fi

    run_sync_operation "$src" "$dest" "$tree_handling" "$template_type" "$transform" "$delete_stale_flag"
    vlog "--- Finished job: $name ---"
  done
}

main() {
  vlog "CHEZMOI_ROOT=$CHEZMOI_ROOT"
  vlog "CHEZMOI_TEMPLATES_ROOT=$CHEZMOI_TEMPLATES_ROOT"

  if [ -n "$CONFIG_FILE" ]; then
    run_batch_job
  else
    run_single_job
  fi
}

main "$@"
