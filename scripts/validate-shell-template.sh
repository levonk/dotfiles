#!/usr/bin/env bash
# Validate that shell scripts and shell templates enable strict mode early.
# Enforces: presence of 'set -euo pipefail' within the first 20 lines.
# Usage (pre-commit passes files as args):
#   scripts/validate-shell-template.sh <files...>
set -euo pipefail

fail=0

check_file() {
  local f="$1"
  # Only check shell scripts and chezmoi shell templates
  case "$f" in
    *.sh|*.sh.tmpl|*.ps1.tmpl) : ;;
    *) return 0 ;;
  esac

  # Shell scripts/templates: strict mode, line-2 no '{{-', no '-}}' at EOF
  if [[ "$f" == *.sh || "$f" == *.sh.tmpl ]]; then
    if awk 'NR<=20 && /set -euo pipefail/ {found=1; exit} END{exit (found?0:1)}' "$f"; then :; else
      echo "[ERROR] Missing 'set -euo pipefail' in the first 20 lines: $f" >&2
      fail=1
    fi
    # Line 2 must not include '{{-' (prevents shebang concatenation)
    second_line=$(sed -n '2p' "$f" || true)
    if [[ "$second_line" == *"{{-"* ]]; then
      echo "[ERROR] Found '{{-' on line 2 (can glue tokens with shebang): $f" >&2
      fail=1
    fi
    # Last non-empty line must not end with '-}}' (preserve trailing newline)
    last_nonempty=$(awk 'NF{ln=$0} END{print ln}' "$f" || true)
    if [[ "$last_nonempty" =~ -\}\}$ ]]; then
      echo "[ERROR] Last non-empty line ends with '-}}' (strips trailing newline): $f" >&2
      fail=1
    fi
    return 0
  fi

  # PowerShell templates: first non-empty line must start with a template if-guard
  if [[ "$f" == *.ps1.tmpl ]]; then
    first_nonempty=$(awk 'NF{print; exit}' "$f" || true)
    # Accept trimmed markers: '{{ if' or '{{- if'
    if [[ ! "$first_nonempty" =~ ^\{\{-?[[:space:]]*if[[:space:]] ]]; then
      echo "[ERROR] .ps1.tmpl must start with an OS guard like '{{ if eq .chezmoi.os \"windows\" }}': $f" >&2
      fail=1
    fi
    # Warn if '#Requires' appears before the first guard
    requires_line=$(grep -n '^#Requires' "$f" | cut -d: -f1 | head -n1 || true)
    guard_line=$(grep -n '^{{[[:space:]]*if' "$f" | cut -d: -f1 | head -n1 || true)
    if [[ -n "${requires_line:-}" && -n "${guard_line:-}" && "$requires_line" -lt "$guard_line" ]]; then
      echo "[ERROR] '#Requires' must be inside the OS guard, not before it: $f" >&2
      fail=1
    fi
    return 0
  fi
}

if [[ "$#" -eq 0 ]]; then
  # If no args, scan default paths (useful for manual runs)
  while IFS= read -r -d '' f; do
    check_file "$f" || true
  done < <(find home/.chezmoiscripts -type f \( -name '*.sh' -o -name '*.sh.tmpl' -o -name '*.ps1.tmpl' \) -print0)
else
  for f in "$@"; do
    check_file "$f" || true
  done
fi

exit "$fail"
