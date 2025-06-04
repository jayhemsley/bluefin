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
