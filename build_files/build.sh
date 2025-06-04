#!/bin/bash

set -euxo pipefail

trap '[[ ! $BASH_COMMAND =~ ^(echo|log) ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
	echo "=== $* ==="
}

rsync -rvK --no-times /ctx/system_files/ /

source /ctx/build_files/steps/00-remove-stock-packages.sh
source /ctx/build_files/steps/01-install-packages.sh
source /ctx/build_files/steps/02-ui.sh
source /ctx/build_files/steps/03-overrides.sh
source /ctx/build_files/steps/04-final.sh
source /ctx/build_files/steps/05-signing.sh

rm -rf /tmp/*
rm -rf /var/*
rm -rf /usr/etc
rm -f /.nvimlog
mkdir -p /tmp
mkdir -p /var/tmp \
&& chmod -R 1777 /var/tmp