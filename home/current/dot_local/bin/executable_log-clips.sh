#!/usr/bin/env sh

## clips - like clip but assumes the plucked out portion is numeric and
## outputs the sum of all of the plucked out portions
## http://nklein.com/2012/08/some-simple-tools-for-processing-debug-output-and-log-files/

## If I wanted to add up the number of bytes sent sending successful pages, do:
##   clips '" 200' < apache.log

_dir=$(dirname "$0")
if [ -x "$_dir/log-clip.sh" ]; then
  exec "$_dir/log-clip.sh" --sum "$@"
else
  ## Back-compat path if user has a `clip` binary in PATH
  clip "$@" | awk '// { SUM += $1 } END { printf("%d\n", SUM) }'
fi
