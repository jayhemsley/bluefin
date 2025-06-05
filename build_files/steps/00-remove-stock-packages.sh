#####
## Remove default packages that are a part of Fedora.
#####

REMOVE_DEFAULT_PACKAGES=(
	adw-gtk3-theme
	fedora-bookmarks
	gnome-classic-session
	gnome-initial-setup
	gnome-shell-extension-apps-menu
	gnome-shell-extension-launch-new-instance
	gnome-shell-extension-places-menu
	gnome-shell-extension-window-list
	gnome-software # If a new app is really needed on a per-device basis just use Warehouse.
	gnome-system-monitor
	gnome-tweaks
	httpd-filesystem
	httpd-tools
	malcontent-control
)

log "Remove some unnecessary default packages..."

dnf remove -y "${REMOVE_DEFAULT_PACKAGES[@]}"
dnf autoremove && dnf clean all

log "Default packages removed."
