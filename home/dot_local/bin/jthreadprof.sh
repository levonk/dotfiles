#!/bin/bash
## jthreadprof.sh — JVM thread dump sampler and summarizer
##
## Collects multiple thread dumps from a target JVM using jcmd (preferred) or
## jstack (fallback), then summarizes thread states, hot stack frames, and hot
## threads across samples. Optional Java Flight Recorder (JFR) capture is
## supported when jcmd is available.
##
## Default output root: $XDG_CACHE_HOME/jthreadprof/YYYYMMDD/
##  - Fallback for XDG_CACHE_HOME: ~/.cache
##  - Per-run subdir: HHMMSS-pid-<pid>-<rand>
##  - Artifacts: dumps/, summary.txt, summary.csv, frames.csv, threads.csv, meta.json, recording.jfr (if JFR used)
##
## Usage examples:
##  - jthreadprof.sh --match myapp -n 20 -i 0.5
##  - jthreadprof.sh --pid 12345 --jstack -n 50 -i 0.2
##  - jthreadprof.sh --help
##
## Notes:
##  - Requires permissions to access the target JVM (same user or root).
##  - jcmd typically ships with JDK; jstack may require JDK tools as well.
##  - JFR requires jcmd. When enabled, a recording is started and dumped to
##    the run directory after sampling.
##  - Filters:
##      --threads-filter/--frames-filter: include regex (ERE)
##      --threads-include/--threads-exclude and --frames-include/--frames-exclude
##        give finer control; include applies before exclude.
##      --states-include/--states-exclude for state filtering (counts & JSON)
set -Eeuo pipefail
IFS=$'\n\t'

PROG_NAME="jthreadprof.sh"
VERSION="1.0.0"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" 1>&2; }
log_err()  { printf '[ERROR] %s\n' "$*" 1>&2; }

usage() {
  cat <<'USAGE'
JVM Thread Profiler

Collect multiple thread dumps and summarize states and hot frames.

Usage:
  jthreadprof.sh (--pid PID | --match PATTERN) [options]

Options:
  --pid PID             Target JVM process ID
  --match PATTERN       Case-insensitive substring match against ps cmdline
  -n, --samples N       Number of samples (default: 10)
  -i, --interval SEC    Interval between samples seconds (default: 1)
  --out DIR             Output base directory (default: $XDG_CACHE_HOME/jthreadprof/YYYYMMDD)
  --timeout SEC         Per-sample timeout (default: none)
  --jcmd                Force jcmd Thread.print
  --jstack              Force jstack -l
  --jfr-start           Start a JFR recording for this run (requires jcmd)
  --jfr-settings NAME   JFR settings: profile|default (default: profile)
  --jfr-duration SEC    JFR duration seconds (default: samples*interval)
  --top N               Limit hot frames/threads in text summary (default: 200)
  --json                Also emit summary.json with states/frames/threads
  --format json         Emit only JSON summary (skip text/CSV files)
  --archive             Create a compressed archive of the run directory (.tgz)
  --tar PATH            Create archive at PATH (implies --archive)
  --threads-filter RE   Include only threads whose name matches this ERE (deprecated; use --threads-include)
  --frames-filter RE    Include only stack frames matching this ERE (deprecated; use --frames-include)
  --threads-include RE  Include threads name matching this ERE
  --threads-exclude RE  Exclude threads name matching this ERE
  --frames-include RE   Include frames matching this ERE
  --frames-exclude RE   Exclude frames matching this ERE
  --states-include RE   Include states matching this ERE
  --states-exclude RE   Exclude states matching this ERE
  -h, --help            Show help
  --version             Show version

Examples:
  jthreadprof.sh --match myapp -n 20 -i 0.5
  jthreadprof.sh --pid 12345 --jstack -n 50 -i 0.2
USAGE
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

resolve_pid_by_pattern() {
  local pat="$1"
  # shellcheck disable=SC2009
  ps -eo pid=,cmd= | awk -v IGNORECASE=1 -v p="$pat" '$0 ~ p {print $1 "\t" substr($0, index($0,$2))}'
}

pick_tool() {
  case "$FORCE_TOOL" in
    jcmd)   echo jcmd; return 0;;
    jstack) echo jstack; return 0;;
  esac
  if have_cmd jcmd; then echo jcmd; return 0; fi
  if have_cmd jstack; then echo jstack; return 0; fi
  return 1
}

out_root_default() {
  local xdg="${XDG_CACHE_HOME:-}"; if [[ -z "$xdg" ]]; then xdg="$HOME/.cache"; fi
  local day; day=$(date +%Y%m%d)
  printf '%s/jthreadprof/%s' "$xdg" "$day"
}

json_escape() { python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || perl -MJSON::PP -0777 -ne 'print encode_json($_)' 2>/dev/null || sed ':a;N;$!ba;s/\n/\\n/g;s/\"/\\\"/g;s/\t/\\t/g'; }

write_meta() {
  local f="$1"; shift
  local pid="$1"; shift
  local tool="$1"; shift
  local cmdline
  cmdline="$(tr -d '\0' < "/proc/${pid}/cmdline" 2>/dev/null | sed 's/\x0/ /g' || true)"
  cmdline_json=$(printf '%s' "$cmdline" | json_escape)
  cat >"$f" <<EOF
{
  "program": "${PROG_NAME}",
  "version": "${VERSION}",
  "pid": ${pid},
  "tool": "${tool}",
  "timestamp": "$(date -Is)",
  "cmdline": ${cmdline_json}
}
EOF
}

collect_dump() {
  local tool="$1" pid="$2" out_file="$3" timeout_sec="$4"
  local cmd=()
  if [[ "$tool" == "jcmd" ]]; then
    cmd=(jcmd "$pid" Thread.print)
  else
    cmd=(jstack -l "$pid")
  fi
  if [[ -n "$timeout_sec" ]]; then
    timeout --signal=INT --kill-after=2s "$timeout_sec" "${cmd[@]}" >"$out_file"
  else
    "${cmd[@]}" >"$out_file"
  fi
}

summarize_states() {
  # Count java.lang.Thread.State occurrences across dumps with include/exclude
  grep -h '^[[:space:]]*java.lang.Thread.State:' "$@" \
    | sed -E 's/^[[:space:]]*java.lang.Thread.State:[[:space:]]*//' \
    | awk -v inc="${STATES_INCLUDE:-}" -v exc="${STATES_EXCLUDE:-}" '
        BEGIN { use_inc = (inc != ""); use_exc = (exc != "") }
        {
          if ((use_inc ? $0 ~ inc : 1) && (use_exc ? $0 !~ exc : 1)) c[$0]++
        }
        END { for (k in c) printf "%s,%d\n", k, c[k] }
      ' \
    | sort -t, -k2,2nr -k1,1
}

summarize_frames() {
  # Extract stack frame lines: leading whitespace + 'at ...'
  # Apply optional include/exclude filters via awk.
  grep -h -E '^[[:space:]]+at ' "$@" \
    | sed -E 's/^[[:space:]]*at[[:space:]]+//' \
    | sed -E 's/[[:space:]]*\(.*\)//' \
    | awk -v inc="${FRAMES_INCLUDE:-${FRAMES_FILTER:-}}" -v exc="${FRAMES_EXCLUDE:-}" '
        BEGIN { use_inc = (inc != ""); use_exc = (exc != "") }
        {
          if ((use_inc ? $0 ~ inc : 1) && (use_exc ? $0 !~ exc : 1)) c[$0]++
        }
        END { for (k in c) printf "%s,%d\n", k, c[k] }
      ' \
    | sort -t, -k2,2nr
}

summarize_threads() {
  # Thread header lines contain quotes: "thread-name" tid= nid= ...
  # Apply optional include/exclude filters via awk.
  grep -h -E '^"[^"]+"' "$@" \
    | sed 's/"\([^"]\+\)".*/\1/' \
    | awk -v inc="${THREADS_INCLUDE:-${THREADS_FILTER:-}}" -v exc="${THREADS_EXCLUDE:-}" '
        BEGIN { use_inc = (inc != ""); use_exc = (exc != "") }
        {
          if ((use_inc ? $0 ~ inc : 1) && (use_exc ? $0 !~ exc : 1)) c[$0]++
        }
        END { for (k in c) printf "%s,%d\n", k, c[k] }
      ' \
    | sort -t, -k2,2nr
}

main() {
  local PID="" MATCH="" SAMPLES=10 INTERVAL=1 OUTDIR_BASE="" TIMEOUT="" FORCE_TOOL=""
  local JFR_START=false JFR_SETTINGS="profile" JFR_DURATION=""
  local TOP=200 EMIT_JSON=false MAKE_ARCHIVE=false FORMAT="" TAR_PATH=""
  THREADS_FILTER=""; FRAMES_FILTER=""; THREADS_INCLUDE=""; THREADS_EXCLUDE=""; FRAMES_INCLUDE=""; FRAMES_EXCLUDE=""; STATES_INCLUDE=""; STATES_EXCLUDE=""

  # Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --pid) PID="$2"; shift 2;;
      --match) MATCH="$2"; shift 2;;
      -n|--samples) SAMPLES="$2"; shift 2;;
      -i|--interval) INTERVAL="$2"; shift 2;;
      --out) OUTDIR_BASE="$2"; shift 2;;
      --timeout) TIMEOUT="$2"; shift 2;;
      --jcmd) FORCE_TOOL="jcmd"; shift;;
      --jstack) FORCE_TOOL="jstack"; shift;;
      --jfr-start) JFR_START=true; shift;;
      --jfr-settings) JFR_SETTINGS="$2"; shift 2;;
      --jfr-duration) JFR_DURATION="$2"; shift 2;;
      --top) TOP="$2"; shift 2;;
      --json) EMIT_JSON=true; shift;;
      --archive) MAKE_ARCHIVE=true; shift;;
      --format) FORMAT="$2"; shift 2;;
      --tar) TAR_PATH="$2"; MAKE_ARCHIVE=true; shift 2;;
      --threads-filter) THREADS_FILTER="$2"; shift 2;;
      --frames-filter) FRAMES_FILTER="$2"; shift 2;;
      --threads-include) THREADS_INCLUDE="$2"; shift 2;;
      --threads-exclude) THREADS_EXCLUDE="$2"; shift 2;;
      --frames-include) FRAMES_INCLUDE="$2"; shift 2;;
      --frames-exclude) FRAMES_EXCLUDE="$2"; shift 2;;
      --states-include) STATES_INCLUDE="$2"; shift 2;;
      --states-exclude) STATES_EXCLUDE="$2"; shift 2;;
      -h|--help) usage; exit 0;;
      --version) printf '%s\n' "$VERSION"; exit 0;;
      *) log_err "Unknown argument: $1"; usage; exit 2;;
    esac
  done

  if [[ -z "$PID" && -z "$MATCH" ]]; then
    log_err "Specify --pid or --match"; usage; exit 2
  fi
  if [[ -n "$PID" && -n "$MATCH" ]]; then
    log_err "Use exactly one of --pid or --match"; exit 2
  fi
  if ! [[ "$SAMPLES" =~ ^[0-9]+$ ]] || (( SAMPLES <= 0 )); then
    log_err "--samples must be positive integer"; exit 2
  fi
  if ! [[ "$INTERVAL" =~ ^([0-9]+)(\.[0-9]+)?$ ]]; then
    log_err "--interval must be seconds (integer or decimal)"; exit 2
  fi
  if ! [[ "$TOP" =~ ^[0-9]+$ ]] || (( TOP <= 0 )); then
    log_err "--top must be positive integer"; exit 2
  fi
  if [[ -n "$FORMAT" && "$FORMAT" != "json" ]]; then
    log_err "--format supports only 'json' currently"; exit 2
  fi

  # Resolve PID by pattern if needed
  if [[ -z "$PID" ]]; then
    local matches
    IFS=$'\n' read -r -d '' -a matches < <(resolve_pid_by_pattern "$MATCH" | head -n 50 && printf '\0') || true
    if (( ${#matches[@]} == 0 )); then
      log_err "No processes matched pattern: $MATCH"; exit 3
    fi
    if (( ${#matches[@]} > 1 )); then
      log_err "Pattern matched multiple processes (be more specific):"; printf '%s\n' "${matches[@]}" 1>&2; exit 3
    fi
    PID="${matches[0]%%$'\t'*}"
  fi
  if ! [[ -r "/proc/$PID" ]]; then
    log_err "PID not accessible: $PID"; exit 3
  fi

  # Tool selection
  local TOOL
  if ! TOOL=$(FORCE_TOOL="$FORCE_TOOL" pick_tool); then
    log_err "Neither jcmd nor jstack found in PATH"; exit 4
  fi
  log_info "Using tool: $TOOL for PID $PID"

  # Output directories
  local OUT_BASE
  OUT_BASE="${OUTDIR_BASE:-$(out_root_default)}"
  mkdir -p "$OUT_BASE"
  local run_id
  run_id="$(date +%H%M%S)-pid-${PID}-$(hexdump -n 2 -e '2/1 "%02x"' /dev/urandom 2>/dev/null || echo rnd)"
  local RUN_DIR="$OUT_BASE/$run_id"
  local DUMPS_DIR="$RUN_DIR/dumps"
  mkdir -p "$DUMPS_DIR"

  # latest symlink
  ( cd "$OUT_BASE" && ln -sfn "$run_id" latest ) || true

  write_meta "$RUN_DIR/meta.json" "$PID" "$TOOL"

  log_info "Writing to: $RUN_DIR"
  log_info "Samples: $SAMPLES every $INTERVAL sec"

  # Optionally start JFR recording
  local REC_NAME="jthreadprof-$run_id"
  local JFR_FILE="$RUN_DIR/recording.jfr"
  if [[ "$JFR_START" == true ]]; then
    if have_cmd jcmd; then
      local dur
      if [[ -n "$JFR_DURATION" ]]; then
        dur="$JFR_DURATION"
      else
        # Compute samples*interval with python for decimals
        dur=$(python3 - <<PY 2>/dev/null || echo "$SAMPLES"
import math
print(max(1, math.ceil(float("$SAMPLES")*float("$INTERVAL"))))
PY
        )
      fi
      log_info "Starting JFR: name=$REC_NAME settings=$JFR_SETTINGS duration=${dur}s"
      if ! jcmd "$PID" JFR.start name="$REC_NAME" settings="$JFR_SETTINGS" filename="$JFR_FILE" dumponexit=true duration="${dur}s" >/dev/null 2>&1; then
        log_warn "Failed to start JFR (continuing without JFR)."
        JFR_START=false
      fi
    else
      log_warn "jcmd not available; cannot start JFR."
      JFR_START=false
    fi
  fi

  # Sampling loop
  local i
  for (( i=1; i<=SAMPLES; i++ )); do
    local idx
    printf -v idx '%03d' "$i"
    local out_file="$DUMPS_DIR/dump-$idx.txt"
    if ! collect_dump "$TOOL" "$PID" "$out_file" "$TIMEOUT"; then
      log_warn "Sample $i failed"
    fi
    if (( i < SAMPLES )); then
      # sleep supports decimals via usleep fallback in bash? use python or sleep with fractional if available
      python3 - <<PY 2>/dev/null || sleep "$INTERVAL"
import time
time.sleep(float("$INTERVAL"))
PY
    fi
  done

  # Summaries
  local dumps_glob=("$DUMPS_DIR"/dump-*.txt)
  if [[ "$FORMAT" != "json" ]]; then
    {
      echo "== Thread State Counts (state,count) =="
      summarize_states "${dumps_glob[@]}" || true
      echo
      echo "== Hot Frames (frame,count) =="
      summarize_frames "${dumps_glob[@]}" | head -n "$TOP" || true
      echo
      echo "== Hot Threads (thread,count) =="
      summarize_threads "${dumps_glob[@]}" | head -n "$TOP" || true
    } >"$RUN_DIR/summary.txt"

    summarize_states "${dumps_glob[@]}" >"$RUN_DIR/summary.csv" || true
    summarize_frames "${dumps_glob[@]}" >"$RUN_DIR/frames.csv" || true
    summarize_threads "${dumps_glob[@]}" >"$RUN_DIR/threads.csv" || true
  fi

  # Optional JSON summary
  if [[ "$EMIT_JSON" == true || "$FORMAT" == "json" ]]; then
    if [[ "$FORMAT" == "json" ]]; then
      # Parse dumps directly to avoid creating CSV files
      python3 - "$DUMPS_DIR" "$RUN_DIR" \
               "${THREADS_INCLUDE:-${THREADS_FILTER:-}}" "${THREADS_EXCLUDE:-}" \
               "${FRAMES_INCLUDE:-${FRAMES_FILTER:-}}" "${FRAMES_EXCLUDE:-}" \
               "${STATES_INCLUDE:-}" "${STATES_EXCLUDE:-}" <<'PY' 2>/dev/null || true
import json, os, re, sys
dumps_dir, run_dir, th_inc, th_exc, fr_inc, fr_exc, st_inc, st_exc = sys.argv[1:9]
th_inc_pat = re.compile(th_inc) if th_inc else None
th_exc_pat = re.compile(th_exc) if th_exc else None
fr_inc_pat = re.compile(fr_inc) if fr_inc else None
fr_exc_pat = re.compile(fr_exc) if fr_exc else None
st_inc_pat = re.compile(st_inc) if st_inc else None
st_exc_pat = re.compile(st_exc) if st_exc else None
states = {}
frames = {}
threads = {}
def inc(d, k):
    d[k] = d.get(k, 0) + 1
for name in sorted(os.listdir(dumps_dir)):
    if not name.endswith('.txt'): continue
    with open(os.path.join(dumps_dir, name), 'r', errors='ignore') as f:
        for line in f:
            if line.startswith('  java.lang.Thread.State:') or line.lstrip().startswith('java.lang.Thread.State:'):
                state = line.split(':',1)[1].strip()
                if (st_inc_pat and not st_inc_pat.search(state)) or (st_exc_pat and st_exc_pat.search(state)):
                    continue
                inc(states, state)
            elif line.lstrip().startswith('at '):
                frame = line.strip()[3:]
                frame = re.sub(r'\s*\(.*\)\s*$', '', frame)
                if (fr_inc_pat and not fr_inc_pat.search(frame)) or (fr_exc_pat and fr_exc_pat.search(frame)):
                    continue
                inc(frames, frame)
            elif line.startswith('"'):
                # Thread header line
                m = re.match(r'^"([^"]+)"', line)
                if m:
                    tname = m.group(1)
                    if (th_inc_pat and not th_inc_pat.search(tname)) or (th_exc_pat and th_exc_pat.search(tname)):
                        continue
                    inc(threads, tname)
out = {
  'states': [{'key': k, 'count': v} for k, v in sorted(states.items(), key=lambda kv: (-kv[1], kv[0]))],
  'frames': [{'key': k, 'count': v} for k, v in sorted(frames.items(), key=lambda kv: -kv[1])],
  'threads': [{'key': k, 'count': v} for k, v in sorted(threads.items(), key=lambda kv: -kv[1])],
}
with open(os.path.join(run_dir, 'summary.json'), 'w') as f:
    json.dump(out, f, indent=2)
PY
    else
      python3 - "$RUN_DIR" <<'PY' 2>/dev/null || true
import csv, json, os, sys
run_dir = sys.argv[1]
def read_csv(path):
    arr = []
    if not os.path.exists(path):
        return arr
    with open(path, newline='') as f:
        for row in csv.reader(f):
            if len(row) >= 2:
                try:
                    arr.append({"key": row[0], "count": int(row[1])})
                except Exception:
                    pass
    return arr
out = {
  "states": read_csv(os.path.join(run_dir, "summary.csv")),
  "frames": read_csv(os.path.join(run_dir, "frames.csv")),
  "threads": read_csv(os.path.join(run_dir, "threads.csv")),
}
with open(os.path.join(run_dir, "summary.json"), "w") as f:
    json.dump(out, f, indent=2)
PY
    fi
  fi

  # Optional archive of the run directory
  if [[ "$MAKE_ARCHIVE" == true ]]; then
    local base dest
    base="$(basename "$RUN_DIR")"
    if [[ -n "$TAR_PATH" ]]; then
      dest="$TAR_PATH"
      case "$dest" in
        *.tgz|*.tar.gz) :;;
        *) dest="${dest}.tgz";;
      esac
      ( cd "$OUT_BASE" && tar -czf "$dest" "$base" ) && log_info "Archive created: $OUT_BASE/$dest" || log_warn "Failed to create archive"
    else
      ( cd "$OUT_BASE" && tar -czf "$base.tgz" "$base" ) && log_info "Archive created: $OUT_BASE/$base.tgz" || log_warn "Failed to create archive"
    fi
  fi

  # Dump and stop JFR if it was started
  if [[ "$JFR_START" == true ]] && have_cmd jcmd; then
    log_info "Finalizing JFR recording..."
    jcmd "$PID" JFR.dump name="$REC_NAME" filename="$JFR_FILE" >/dev/null 2>&1 || true
    jcmd "$PID" JFR.stop name="$REC_NAME" >/dev/null 2>&1 || true
    if [[ -s "$JFR_FILE" ]]; then
      log_info "JFR saved: $JFR_FILE"
    else
      log_warn "JFR file not created."
    fi
  fi

  log_info "Done. See $RUN_DIR"
}

main "$@"
