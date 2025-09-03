#!/usr/bin/env bash
# Run list for troubleshooting network connections
# Enhanced: strict mode, timeouts, fallbacks, labeled output, exit codes.
# Usage:
#   checkNetAccess.sh [HOST] [PORT] [--no-icmp] [--no-trace] [--timeout N] [--json]
# Defaults: HOST=1.1.1.1 PORT=80 TIMEOUT=3

set -euo pipefail

HOST=${1:-}
PORT=${2:-}
shift || true 2>/dev/null || true
shift || true 2>/dev/null || true

NO_ICMP=false
NO_TRACE=false
TIMEOUT=3
FORMAT="human"  # or json

# Parse flags (remaining args)
for arg in "$@"; do
  case "$arg" in
    --no-icmp) NO_ICMP=true ;;
    --no-trace) NO_TRACE=true ;;
    --timeout) shift; TIMEOUT=${1:-3} ;;
    --json) FORMAT="json" ;;
    -h|--help)
      sed -n '1,40p' "$0"; exit 0 ;;
    *) ;; # ignore unknowns for now
  esac
  shift || true
done

REMOTE_SERVICE=${HOST:-1.1.1.1}
REMOTE_PORT=${PORT:-80}

# Helpers
have() { command -v "$1" >/dev/null 2>&1; }
hr() { printf '%s\n' "------------------------------------------------------------"; }

json_escape() { sed -e 's/\\/\\\\/g' -e 's/\"/\\\"/g' -e 's/\t/\\t/g' -e 's/\r/\\r/g' -e 's/\n/\\n/g'; }

# Storage
DNS_OUTPUT=""; DNS_OK=0
TCP_OUTPUT=""; TCP_OK=0
TRACE_OUTPUT=""; TRACE_OK=0
EXTIP_OUTPUT=""; EXTIP_OK=0
INTIP_OUTPUT=""; INTIP_OK=0
ICMP_OUTPUT=""; ICMP_OK=0

echo_section() { printf "[%s] %s\n" "$1" "$2"; }

# ---------------------------------------------------------------------------
# see if hostname is resolvable (keep original comment)
# Attempt with dig, fallback to getent/host.
if have dig; then
  if DNS_OUTPUT=$(timeout "${TIMEOUT}" dig +short "${REMOTE_SERVICE}" 2>&1); then DNS_OK=1; fi
elif have getent; then
  if DNS_OUTPUT=$(timeout "${TIMEOUT}" getent hosts "${REMOTE_SERVICE}" 2>&1); then DNS_OK=1; fi
elif have host; then
  if DNS_OUTPUT=$(timeout "${TIMEOUT}" host "${REMOTE_SERVICE}" 2>&1); then DNS_OK=1; fi
else
  DNS_OUTPUT="No resolver tool (dig/getent/host) available"; DNS_OK=0
fi

# ---------------------------------------------------------------------------
# check the port connectivity (keep original comment)
# Try nc, fallback to bash /dev/tcp and curl.
if have nc; then
  if TCP_OUTPUT=$(timeout "${TIMEOUT}" nc -vz "${REMOTE_SERVICE}" "${REMOTE_PORT}" 2>&1); then TCP_OK=1; fi
elif [[ -w /dev/tcp/localhost/80 || 1 -eq 1 ]]; then
  # Bash TCP (no detailed output)
  if timeout "${TIMEOUT}" bash -c "</dev/tcp/${REMOTE_SERVICE}/${REMOTE_PORT}" 2>/dev/null; then
    TCP_OUTPUT="Connected to ${REMOTE_SERVICE}:${REMOTE_PORT} (via /dev/tcp)"; TCP_OK=1
  else
    TCP_OUTPUT="Connection to ${REMOTE_SERVICE}:${REMOTE_PORT} failed (/dev/tcp)"; TCP_OK=0
  fi
elif have curl; then
  if TCP_OUTPUT=$(curl -sS -o /dev/null --connect-timeout "${TIMEOUT}" "http://${REMOTE_SERVICE}:${REMOTE_PORT}" 2>&1); then TCP_OK=1; fi
else
  TCP_OUTPUT="No TCP tool (nc/bash/curl) available"; TCP_OK=0
fi

# ---------------------------------------------------------------------------
# ICMP reachability (optional)
if [[ "${NO_ICMP}" != true ]]; then
  if have ping; then
    if ICMP_OUTPUT=$(timeout "${TIMEOUT}" ping -c1 -W "${TIMEOUT}" "${REMOTE_SERVICE}" 2>&1); then ICMP_OK=1; fi
  else
    ICMP_OUTPUT="ping not available"; ICMP_OK=0
  fi
fi

# ---------------------------------------------------------------------------
# trace the route (keep original comment)
if [[ "${NO_TRACE}" != true ]]; then
  if have traceroute; then
    if TRACE_OUTPUT=$(timeout $((TIMEOUT*2)) traceroute -m 20 "${REMOTE_SERVICE}" 2>&1); then TRACE_OK=1; fi
  elif have tracepath; then
    if TRACE_OUTPUT=$(timeout $((TIMEOUT*2)) tracepath -m 20 "${REMOTE_SERVICE}" 2>&1); then TRACE_OK=1; fi
  else
    TRACE_OUTPUT="No traceroute/tracepath available"; TRACE_OK=0
  fi
fi

# ---------------------------------------------------------------------------
# get outbound IP address (keep original comment)
# Try multiple services with short timeouts.
if have curl; then
  for svc in "https://icanhazip.com" "https://ifconfig.me" "https://api.ipify.org"; do
    if EXTIP_OUTPUT=$(curl -fsS --max-time "${TIMEOUT}" --connect-timeout "${TIMEOUT}" "$svc" 2>/dev/null); then
      EXTIP_OUTPUT=${EXTIP_OUTPUT//$'\n'/}
      EXTIP_OK=1; break
    fi
  done
else
  EXTIP_OUTPUT="curl not available"; EXTIP_OK=0
fi

# ---------------------------------------------------------------------------
# get the internal IP to submit proper request (keep original comment)
if have ip; then
  if INTIP_OUTPUT=$(ip -4 addr show | awk '/inet /{print $2, $NF}'); then
    INTIP_OK=1
  else
    INTIP_OK=0
  fi
elif have ifconfig; then
  if INTIP_OUTPUT=$(ifconfig | grep inet | awk '{print $2, $1}'); then
    INTIP_OK=1
  else
    INTIP_OK=0
  fi
else
  INTIP_OUTPUT="ip/ifconfig not available"; INTIP_OK=0
fi

# ---------------------------------------------------------------------------
# Output
if [[ "${FORMAT}" == "json" ]]; then
  printf '{'
  printf '"Host":"%s",' "${REMOTE_SERVICE}" | json_escape
  printf '"Port":"%s",' "${REMOTE_PORT}" | json_escape
  printf '"DNS":{ "ok":%s,"out":"%s" },' "$((DNS_OK))" "$(printf '%s' "${DNS_OUTPUT}" | json_escape)"
  printf '"TCP":{ "ok":%s,"out":"%s" },' "$((TCP_OK))" "$(printf '%s' "${TCP_OUTPUT}" | json_escape)"
  printf '"ICMP":{ "ok":%s,"out":"%s" },' "$((ICMP_OK))" "$(printf '%s' "${ICMP_OUTPUT}" | json_escape)"
  printf '"Trace":{ "ok":%s,"out":"%s" },' "$((TRACE_OK))" "$(printf '%s' "${TRACE_OUTPUT}" | json_escape)"
  printf '"ExternalIP":{ "ok":%s,"out":"%s" },' "$((EXTIP_OK))" "$(printf '%s' "${EXTIP_OUTPUT}" | json_escape)"
  printf '"InternalIP":{ "ok":%s,"out":"%s" }' "$((INTIP_OK))" "$(printf '%s' "${INTIP_OUTPUT}" | json_escape)"
  printf '}\n'
else
  hr; echo_section INFO "Target: ${REMOTE_SERVICE}:${REMOTE_PORT}  Timeout: ${TIMEOUT}s"; hr
  echo_section DNS     "ok=${DNS_OK}";      printf '%s\n' "${DNS_OUTPUT}"; hr
  echo_section TCP     "ok=${TCP_OK}";      printf '%s\n' "${TCP_OUTPUT}"; hr
  if [[ "${NO_ICMP}" != true ]]; then echo_section ICMP    "ok=${ICMP_OK}";    printf '%s\n' "${ICMP_OUTPUT}"; hr; fi
  if [[ "${NO_TRACE}" != true ]]; then echo_section TRACE   "ok=${TRACE_OK}";   printf '%s\n' "${TRACE_OUTPUT}"; hr; fi
  echo_section EXT_IP  "ok=${EXTIP_OK}";   printf '%s\n' "${EXTIP_OUTPUT}"; hr
  echo_section INT_IP  "ok=${INTIP_OK}";   printf '%s\n' "${INTIP_OUTPUT}"; hr
fi

# Exit code: 0 if DNS+TCP succeeded, else 1 (ICMP/Trace not required)
if [[ ${DNS_OK} -eq 1 && ${TCP_OK} -eq 1 ]]; then exit 0; else exit 1; fi
