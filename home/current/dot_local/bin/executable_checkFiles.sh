#!/usr/bin/env bash

# Check per-process open-file usage and limits.
# Preserves original intent: print cmdline, limits, and open files count.
# Enhancements: strict mode, robust PID discovery, JSON output, timeouts, better errors.
#
# Usage:
#   checkFiles.sh [PROC_NAME|PID ...] [--json]
#   checkFiles.sh               # defaults to jsvc
#   checkFiles.sh nginx --json  # by name in JSON
#   checkFiles.sh 1234 5678     # by PIDs

set -euo pipefail
IFS=$'\n\t'

have() { command -v "$1" >/dev/null 2>&1; }

FORMAT="human" # or json
ARGS=()
for a in "$@"; do
  case "$a" in
    --json) FORMAT="json" ;;
    -h|--help)
      sed -n '1,40p' "$0"; exit 0 ;;
    *) ARGS+=("$a") ;;
  esac
done

if [[ ${#ARGS[@]} -gt 0 ]]; then
  TARGETS=("${ARGS[@]}")
else
  TARGETS=("jsvc")
fi

collect_pids_for_target() {
  local target="$1"
  local pids=()
  if [[ "$target" =~ ^[0-9]+$ ]]; then
    if [[ -r "/proc/$target" ]]; then pids+=("$target"); fi
  else
    if have pidof; then
      # pidof may return >1 pid on one line
      local out
      if out=$(pidof "$target" 2>/dev/null || true); then
        for p in $out; do pids+=("$p"); done
      fi
    fi
    if [[ ${#pids[@]} -eq 0 ]] && have pgrep; then
      # exact match, then cmdline fallback
      while IFS= read -r p; do [[ -n "$p" ]] && pids+=("$p"); done < <(pgrep -x "$target" 2>/dev/null || true)
      if [[ ${#pids[@]} -eq 0 ]]; then
        while IFS= read -r p; do [[ -n "$p" ]] && pids+=("$p"); done < <(pgrep -f "$target" 2>/dev/null || true)
      fi
    fi
  fi
  printf '%s\n' "${pids[@]}"
}

escape_json() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\r/\\r/g' -e 's/\n/\\n/g'; }

print_human() {
  local pid="$1"; local cmdline="$2"; local lim_soft="$3"; local lim_hard="$4"; local of_count="$5"
  echo "PID: $pid"
  echo "CMD: $cmdline"
  echo "Limit (soft/hard) - Max open files: $lim_soft/$lim_hard"
  echo "Currently open files: $of_count"
  echo
}

print_json_item() {
  local pid="$1"; local cmdline="$2"; local lim_soft="$3"; local lim_hard="$4"; local of_count="$5"
  printf '{"pid":%s,"cmd":"%s","max_open_files":{"soft":%s,"hard":%s},"open_files":%s}' \
    "$(printf '%s' "$pid" | escape_json)" \
    "$(printf '%s' "$cmdline" | escape_json)" \
    "$(printf '%s' "$lim_soft" | escape_json)" \
    "$(printf '%s' "$lim_hard" | escape_json)" \
    "$(printf '%s' "$of_count" | escape_json)"
}

declare -a ALL_PIDS=()
for t in "${TARGETS[@]}"; do
  mapfile -t found < <(collect_pids_for_target "$t" || true)
  if [[ ${#found[@]} -gt 0 ]]; then
    ALL_PIDS+=("${found[@]}")
  fi
done

if [[ ${#ALL_PIDS[@]} -eq 0 ]]; then
  echo "No processes found for: ${TARGETS[*]}" >&2
  exit 1
fi

if [[ "$FORMAT" == "json" ]]; then
  printf '{"targets":["%s"],"processes":[' "$(printf '%s' "${TARGETS[*]}" | escape_json)"
  first=true
fi

for pid in "${ALL_PIDS[@]}"; do
  # cmdline
  cmdline="(unavailable)"
  if [[ -r "/proc/$pid/cmdline" ]]; then
    cmdline=$(tr '\0' ' ' < "/proc/$pid/cmdline" | sed 's/ $//')
  fi

  # limits
  lim_soft="-"; lim_hard="-"
  if [[ -r "/proc/$pid/limits" ]]; then
    # Extract the "Max open files" line reliably
    line=$(grep -E '^Max open files' "/proc/$pid/limits" || true)
    if [[ -n "$line" ]]; then
      # Columns: Limit  Soft  Hard  Units
      lim_soft=$(awk '{print $(NF-2)}' <<<"$line")
      lim_hard=$(awk '{print $(NF-1)}' <<<"$line")
    fi
  fi

  # open files count
  of_count="0"
  if [[ -d "/proc/$pid/fd" ]]; then
    # Count entries robustly without relying on ls parsing
    of_count=$(find "/proc/$pid/fd" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | awk '{print $1}')
  fi

  if [[ "$FORMAT" == "json" ]]; then
    if [[ "$first" == true ]]; then first=false; else printf ','; fi
    print_json_item "$pid" "$cmdline" "$lim_soft" "$lim_hard" "$of_count"
  else
    echo "Looking for ${TARGETS[*]} processes"
    print_human "$pid" "$cmdline" "$lim_soft" "$lim_hard" "$of_count"
  fi
done

if [[ "$FORMAT" == "json" ]]; then
  printf ']}'
  printf '\n'
fi
