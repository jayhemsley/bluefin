#!/bin/bash

set -euo pipefail
[[ -n "${SET_X:-}" ]] && set -x

trap '[[ ! $BASH_COMMAND =~ ^(echo|log) ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

echo "libhardened_malloc.so" | tee -a /etc/ld.so.preload > /dev/null
# chmod 444 /etc/ld.so.preload