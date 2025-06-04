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

rm -rf /tmp/* || true
find /var/* -maxdepth 0 -type d \! -name cache -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;