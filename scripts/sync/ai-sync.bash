#!/usr/bin/env bash

# ai-sync.bash — Generate reference-mode Go template includes for AI workflows
#
# Based on: internal-docs/requirements/ai-sync-script/ai-sync-script-requirements.md
#
# Sources:
#   $CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/**.md
# Destinations (flatten=true):
#   $CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/
#   $CHEZMOI_ROOT/dot_codeium/windsurf-next/global_workflows/
#
# Key behavior:
# - Always output .md.tmpl (append .tmpl)
# - Each destination file contains exactly one line: {{ includeTemplate "dot_config/ai/<relative>" . }}
# - Respect .gitignore (skip ignored sources)
# - Flattening conflict resolution and warnings; --force overwrites; --quiet suppresses warnings
# - --delete-stale removes .md.tmpl files whose include target no longer exists

set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
REPO_ROOT=$(CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P)

# Defaults; allow overrides
CHEZMOI_ROOT_DEFAULT="$REPO_ROOT/home/current"
CHEZMOI_ROOT="${CHEZMOI_ROOT:-$CHEZMOI_ROOT_DEFAULT}"
CHEZMOI_TEMPLATES_ROOT="${CHEZMOI_TEMPLATES_ROOT:-$CHEZMOI_ROOT/.chezmoitemplates}"

SRC_WORKFLOWS_ROOT="$CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows"

DST_WINDSURF_ROOT="$CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows"
DST_WINDSURF_NEXT_ROOT="$CHEZMOI_ROOT/dot_codeium/windsurf-next/global_workflows"

DRY_RUN=0
VERBOSE=0
DELETE_STALE=0
FORCE=0
QUIET=0

log() { printf '%s\n' "$*"; }
vlog() { if [ "$VERBOSE" -eq 1 ]; then printf '%s\n' "$*"; fi; }
warn() { [ "$QUIET" -eq 1 ] || printf 'warn: %s\n' "$*" >&2; }
err() { printf 'error: %s\n' "$*" >&2; }

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--dry-run] [--verbose|-v] [--delete-stale] [--force] [--quiet]

Generates reference .md.tmpl files that include sources from:
  $SRC_WORKFLOWS_ROOT

Destinations (flattened):
  $DST_WINDSURF_ROOT
  $DST_WINDSURF_NEXT_ROOT

Env overrides:
  CHEZMOI_ROOT (default: $CHEZMOI_ROOT_DEFAULT)
  CHEZMOI_TEMPLATES_ROOT (default: $CHEZMOI_ROOT/.chezmoitemplates)
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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

# If file is a single includeTemplate line, print target path and return 0; else return 1
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
  if printf '%s' "$line" | grep -Eq '^\{\{\s*includeTemplate\s+"[^"]+"\s+\.\s*\}\}$'; then
    printf '%s\n' "$line" | sed -E 's/^\{\{\s*includeTemplate\s+"([^"]+)"\s+\.\s*\}\}$/\1/'
    return 0
  fi
  return 1
}

write_include_file() {
  local dst_file="$1"; shift
  local include_path="$1"; shift
  ensure_dir "$(dirname -- "$dst_file")"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "Would write: $dst_file <- {{ includeTemplate \"$include_path\" . }}"
  else
    printf '{{ includeTemplate "%s" . }}\n' "$include_path" >"$dst_file"
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
  local src_root="$1"
  local dst_root="$2"
  local flatten="$3"
  local src_file="$4"

  local rel
  rel="${src_file#"$src_root"/}"
  local rel_no_ext="${rel%.md}"
  local base
  base="$(basename -- "$rel_no_ext")"
  local dir_rel
  dir_rel="$(dirname -- "$rel_no_ext")"
  [ "$dir_rel" = "." ] && dir_rel=""

  local include_path="dot_config/ai/workflows/$rel"

  local candidate_dst
  if [ "$flatten" = "1" ]; then
    candidate_dst="$dst_root/$base.md.tmpl"
  else
    candidate_dst="$dst_root/$rel_no_ext.md.tmpl"
  fi

  ensure_dir "$dst_root"

  if [ -f "$candidate_dst" ]; then
    local existing_target=""
    if existing_target=$(extract_include_target_from_file "$candidate_dst" 2>/dev/null); then
      if [ "$existing_target" = "$include_path" ]; then
        vlog "Up-to-date: $candidate_dst includes $include_path"
        return 0
      fi
      if [ "$flatten" = "1" ]; then
        # Disambiguate with dir prefix (slashes and spaces -> underscores)
        local prefix=""
        if [ -n "$dir_rel" ]; then
          prefix="$(printf '%s' "$dir_rel" | tr '/ ' '__')_"
        fi
        local final_dst="$dst_root/${prefix}${base}.md.tmpl"
        warn "flatten conflict: existing=$candidate_dst includes=$existing_target; attempted=$include_path; writing=$final_dst"

        if [ -f "$final_dst" ]; then
          local existing2=""
          if existing2=$(extract_include_target_from_file "$final_dst" 2>/dev/null); then
            if [ "$existing2" = "$include_path" ]; then
              vlog "Disambiguated already correct: $final_dst"
              return 0
            else
              if [ "$FORCE" -eq 1 ]; then
                write_include_file "$final_dst" "$include_path"
                return 0
              fi
              warn "disambiguated exists with different include; skip (use --force): $final_dst includes=$existing2 attempted=$include_path"
              return 0
            fi
          else
            if [ "$FORCE" -eq 1 ]; then
              write_include_file "$final_dst" "$include_path"
              return 0
            fi
            warn "disambiguated path not single-line include; skip (use --force): $final_dst"
            return 0
          fi
        else
          write_include_file "$final_dst" "$include_path"
          return 0
        fi
      else
        if [ "$FORCE" -eq 1 ]; then
          warn "overwrite: $candidate_dst includes=$existing_target -> $include_path"
          write_include_file "$candidate_dst" "$include_path"
          return 0
        fi
        warn "existing file includes different target; skip (use --force): $candidate_dst includes=$existing_target attempted=$include_path"
        return 0
      fi
    else
      if [ "$FORCE" -eq 1 ]; then
        warn "overwrite non-include file: $candidate_dst"
        write_include_file "$candidate_dst" "$include_path"
        return 0
      fi
      warn "existing file not single-line include; skip (use --force): $candidate_dst"
      return 0
    fi
  else
    write_include_file "$candidate_dst" "$include_path"
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

main() {
  if [ ! -d "$SRC_WORKFLOWS_ROOT" ]; then
    err "Source directory missing: $SRC_WORKFLOWS_ROOT"; exit 2
  fi

  vlog "CHEZMOI_ROOT=$CHEZMOI_ROOT"
  vlog "CHEZMOI_TEMPLATES_ROOT=$CHEZMOI_TEMPLATES_ROOT"

  local dst
  for dst in "$DST_WINDSURF_ROOT" "$DST_WINDSURF_NEXT_ROOT"; do
    ensure_dir "$dst"
    while IFS= read -r -d '' s; do
      process_one_file "$SRC_WORKFLOWS_ROOT" "$dst" "1" "$s"
    done < <(gather_sources "$SRC_WORKFLOWS_ROOT")
    if [ "$DELETE_STALE" -eq 1 ]; then
      delete_stale_in_destination "$dst"
    fi
  done
}

main "$@"
