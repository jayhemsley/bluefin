#!/bin/bash

set -euo pipefail
[[ -n "${SET_X:-}" ]] && set -x

trap '[[ ! $BASH_COMMAND =~ ^(echo|log) ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

echo "${REMOTE_FONTS_URL}"

log "Starting custom image build process..."

rsync -rvK --no-times /ctx/system_files/ /

# GSchema Overrides
# By @bsherman (https://github.com/bsherman)
# https://github.com/bsherman/bos/blob/main/desktop-changes.sh
mkdir -p /tmp/ublue-schema-test &&
    find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/ublue-schema-test/ \; &&
    cp /usr/share/glib-2.0/schemas/*-bos-modifications.gschema.override /tmp/ublue-schema-test/ &&
    echo "Running error test for bos gschema override. Aborting if failed." &&
    glib-compile-schemas --strict /tmp/ublue-schema-test || exit 1 &&
    echo "Compiling gschema to include our overrides" &&
    glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

/ctx/build_files/modules/security.sh
/ctx/build_files/modules/packages.sh
/ctx/build_files/modules/environment.sh
/ctx/build_files/modules/final.sh