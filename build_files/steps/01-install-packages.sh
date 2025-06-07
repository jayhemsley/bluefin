#####
## Layer on additional packages.
#####

LAYERED_PACKAGES=(
	adw-gtk3-theme
	android-tools
	btrfs-assistant
	edk2-ovmf
	firefox
	# librewolf - when the --enable-replace-malloc flag gets merged
	fzf
	gnome-shell-extension-auto-move-windows
	gnome-shell-extension-blur-my-shell
	gnome-shell-extension-caffeine
	gnome-shell-extension-dash-to-dock
	gnome-shell-extension-just-perfection
	hplip
	ifuse
	libcamera-gstreamer
	libcamera-tools
	libratbag-ratbagd
	libva-utils
	libvirt
	libvirt-nss
	lshw
	lxc
	nicstat
	nvtop
	osbuild-selinux
	p7zip-plugins
	podman-compose
	podman-machine
	podman-tui
	powerline-fonts
	powerstat
	powertop
	printer-driver-brlaser
	qemu
	qemu-char-spice
	qemu-device-display-virtio-gpu
	qemu-device-display-virtio-vga
	qemu-device-usb-redirect
	qemu-img qemu-system-x86-core
	qemu-user-binfmt
	qemu-user-static
	restic
	smartmontools
	solaar
	solaar-udev
	tmux
	v4l-utils
	virt-install
	virt-manager
	virt-v2v
	virt-viewer
	wireguard-tools
)

log "Installing layered packages..."

#Add COPRs
dnf -y copr enable ublue-os/staging # gnome-shell-extension-search-light and gnome-shell-extension-power-profile-switcher
dnf -y copr disable ublue-os/staging

 # kcli
dnf -y copr enable karmab/kcli
dnf -y copr disable karmab/kcli

 # podman-bootc
dnf -y copr enable gmaglione/podman-bootc
dnf -y copr disable gmaglione/podman-bootc

# terra and extras, keep it disabled as we'll use it for specific packages only
dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
dnf -y install terra-release-extras || true
dnf config-manager setopt "terra*".enabled=0

# Ensure all repositories are HTTPS
for repo in /etc/yum.repos.d/*.repo; do
	sed -i 's/metalink?/metalink?protocol=https\&/g' "$repo"
done

# Keep installations minimal
dnf install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}"
dnf -y --enablerepo copr:copr.fedorainfracloud.org:karmab:kcli install kcli
dnf -y --enablerepo copr:copr.fedorainfracloud.org:gmaglione:podman-bootc install podman-bootc

# Gnome Extensions (DNF)
dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:staging install gnome-shell-extension-search-light

dnf5 -y upgrade --enablerepo=updates-testing --refresh --advisory=FEDORA-2025-c358833c5d

dnf -y swap \
	--repo="terra, terra-extras" \
	gnome-shell gnome-shell

dnf versionlock add gnome-shell

dnf -y swap \
	--repo="terra, terra-extras" \
	switcheroo-control switcheroo-control

dnf versionlock add switcheroo-control

log "Layered packages installed, disabling all repos..."

# Disable all repos
for i in /etc/yum.repos.d/*.repo; do
	sed -i 's@enabled=1@enabled=0@g' "$i"
done

dnf clean all
