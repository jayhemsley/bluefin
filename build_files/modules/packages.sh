#!/bin/bash

set -euo pipefail
[[ -n "${SET_X:-}" ]] && set -x

trap '[[ ! $BASH_COMMAND =~ ^(echo|log) ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

COPR_REPOS=(
	wojnilowicz/ungoogled-chromium
)

for repo in "${COPR_REPOS[@]}"; do
    dnf -y copr enable "$repo"
done

# Add Librewolf Repo
curl -fsSL https://repo.librewolf.net/librewolf.repo |  tee /etc/yum.repos.d/librewolf.repo
curl -fsSL https://copr.fedorainfracloud.org/coprs/secureblue/hardened_malloc/repo/fedora-42/secureblue-hardened_malloc-fedora-42.repo | tee /etc/yum.repos.d/secureblue-hardened_malloc-fedora-42.repo

log "Ensure https for each repo"
for repo in /etc/yum.repos.d/*.repo; do
    sed -i 's/metalink?/metalink?protocol=https\&/g' "$repo"
done

log "Remove default packages"

REMOVE_DEFAULT_PACKAGES=(
	adcli
	adw-gtk3-theme
	bash-color-prompt
	bazaar
	bcache-tools
	bluefin-fastfetch
	borgbackup
	cryfs
	fastfetch
	fedora-bookmarks
	fedora-chromium-config
	fedora-chromium-config-gnome
	fedora-flathub-remote
	fedora-third-party
	fedora-workstation-repositories
	gnome-extensions-app
	gnome-shell-extension-appindicator
	gnome-shell-extension-apps-menu
	gnome-shell-extension-background-logo
	gnome-shell-extension-caffeine
	gnome-shell-extension-gsconnect
	gnome-shell-extension-launch-new-instance
	gnome-shell-extension-logo-menu
	gnome-shell-extension-places-menu
	gnome-shell-extension-tailscale-gnome-qs
	gnome-shell-extension-window-list
	gnome-system-monitor
	gnome-tour
	gnome-tweaks
	gnome-user-share
	htop
	httpd
	httpd-core
	httpd-filesystem
	httpd-tools
	krb5-workstation
	ibus-mozc
	input-remapper
	libsss_autofs
	libvncserver
	mod_dnssd
	mod_http2
	mod_lua
	mozc
	nautilus-gsconnect
	nerd-fonts
	nvtop
	opendyslexic-fonts
	openrgb-udev-rules
	openssh-askpass
	oversteer-udev
	samba
	samba-dcerpc
	samba-ldb-ldap-modules
	samba-winbind-clients
	samba-winbind-modules
	sssd-ad
	sssd-krb5
	sssd-nfs-idmap
	tailscale
	ublue-bling
	ublue-fastfetch
	ubl
	yaru-theme
	yelp
)

dnf remove -y "${REMOVE_DEFAULT_PACKAGES[@]}"
dnf autoremove && dnf clean all

log "Install RPM packages"

LAYERED_PACKAGES=(
	btrfs-assistant
	firefox
	gnome-shell-extension-auto-move-windows
	gnome-shell-extension-just-perfection
	hardened_malloc
	librewolf
	p7zip
	p7zip-plugins
	solaar
	ungoogled-chromium
	usbguard
	usbguard-notifier
	v4l-utils
)

dnf install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}"

log "Remove unused repos"
rm -f /etc/yum.repos.d/*