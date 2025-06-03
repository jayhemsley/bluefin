#!/bin/bash

set -euo pipefail
[[ -n "${SET_X:-}" ]] && set -x

trap '[[ ! $BASH_COMMAND =~ ^(echo|log) ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

COPR_REPOS=(
	monkeygold/nautilus-open-any-terminal
	secureblue/hardened_malloc
	wojnilowicz/ungoogled-chromium
)

for repo in "${COPR_REPOS[@]}"; do
    dnf -y copr enable "$repo"
done

log "Ensure https for each repo"
for repo in /etc/yum.repos.d/*.repo; do
    sed -i 's/metalink?/metalink?protocol=https\&/g' "$repo"
done

log "Remove default packages"

REMOVE_DEFAULT_PACKAGES=(
	adcli
	adw-gtk3-theme
	android-udev-rules
	bash-color-prompt
	bazaar
	bcache-tools
	bluefin-fastfetch
	borgbackup
	cryfs
	epson-inkjet-printer-escpr
	epson-inkjet-printer-escpr2
	evtest
	fastfetch
	firewall-config
	fedora-bookmarks
	fedora-chromium-config
	fedora-chromium-config-gnome
	fedora-flathub-remote
	fedora-third-party
	fedora-workstation-repositories
	foo2zjs
	fuse
	fuse-encfs
	fzf
	glow
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
	google-noto-fonts-all
	gstreamer1-plugins-ugly-free
	gum
	gvfs-nfs
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
	lshw
	mod_dnssd
	mod_http2
	mod_lua
	mozc
	nautilus-gsconnect
	nautilus-open-any-terminal
	nerd-fonts
	nvtop
	oddjob-mkhomedir
	opendyslexic-fonts
	openrgb-udev-rules
	openssh-askpass
	oversteer-udev
	passim
	powerstat
	powertop
	printer-driver-brlaser
	python3-pip
	python3-pygit2
	rclone
	restic
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
	p7zip
	p7zip-plugins
	plymouth-plugin-script
	solaar
	ungoogled-chromium
	usbguard
	usbguard-notifier
	v4l-utils
)

dnf install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}"

log "Remove unused repos"
rm -f /etc/yum.repos.d/*