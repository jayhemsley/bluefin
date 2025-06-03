#!/bin/bash

set -euo pipefail
[[ -n "${SET_X:-}" ]] && set -x

trap '[[ ! $BASH_COMMAND =~ ^(echo|log) ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Enabling faillock in PAM authentication profile"
authselect enable-feature with-faillock 1> /dev/null

chmod 440 /etc/sudoers.d/timeout

log "Create missing directory for USBGuard"
# https://bugzilla.redhat.com/show_bug.cgi?id=2259249
mkdir -p /var/log/usbguard

# Disable unnecessary services
log "Disable unnecessary services"

systemctl disable sshd
systemctl mask sshd

systemctl disable avahi-daemon
systemctl mask avahi-daemon

systemctl disable ModemManager
systemctl mask ModemManager

systemctl disable nfs-idmapd
systemctl mask nfs-idmapd

systemctl disable nfs-mountd
systemctl mask nfs-mountd

systemctl disable nfsdcld
systemctl mask nfsdcld

systemctl disable rpc-gssd
systemctl mask rpc-gssd

systemctl disable rpc-statd-notify
systemctl mask rpc-statd-notify

systemctl disable rpc-statd
systemctl mask rpc-statd

systemctl disable rpcbind
systemctl mask rpcbind

systemctl disable gssproxy
systemctl mask gssproxy

systemctl disable uresourced.service
systemctl mask uresourced.service

systemctl disable low-memory-monitor.service
systemctl mask low-memory-monitor.service

systemctl disable thermald.service
systemctl mask thermald.service

systemctl disable sssd
systemctl mask sssd

systemctl disable sssd-kcm
systemctl mask sssd-kcm

systemctl disable cups
systemctl mask cups

systemctl disable cups-browsed
systemctl mask cups-browsed