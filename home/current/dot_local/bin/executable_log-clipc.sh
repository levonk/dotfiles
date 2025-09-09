#!/usr/bin/env sh

## clipc - like clip except counts the number of occurrences of each
## unique plucked-out portion
## http://nklein.com/2012/08/some-simple-tools-for-processing-debug-output-and-log-files/

## Examples (kept for reference):
##   Get paths and the number of times accessed from apache.log
##     clipc GET < apache.log | sort -n
##   How often GET from various IPs:
##     clipc '^' '- .* "GET' < apache.log
##   Busiest minute:
##     clipc '\[' ':\d\d ' < apache.log | sort -nr | head -1

## Prefer the co-located modern script if available; fall back to `clip` otherwise
_dir=$(dirname "$0")
if [ -x "$_dir/log-clip.sh" ]; then
  exec "$_dir/log-clip.sh" --count "$@"
else
  ## Back-compat path if user has a `clip` binary in PATH
  clip "$@" | sort | uniq -c | sed -e 's/^ *//'
fi
