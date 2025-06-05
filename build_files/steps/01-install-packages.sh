#####
## Layer on additional packages.
#####

LAYERED_PACKAGES=(
	android-tools
	btrfs-assistant
	edk2-ovmf
	fzf
	gnome-shell-extension-auto-move-windows
	gnome-shell-extension-blur-my-shell
	gnome-shell-extension-caffeine
	gnome-shell-extension-dash-to-dock
	gnome-shell-extension-just-perfection
	hplip
	ifuse
	kcli
	libcamera-gstreamer
	libcamera-tools
	libratbag-ratbagd
	librewolf
	libva-utils
	libvirt
	libvirt-nss
	lshw
	lxc
	nicstat
	nvtop
	osbuild-selinux
	p7zip-plugins
	podman-bootc
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
	ublue-polkit-rules
	uupd
	v4l-utils
	virt-install
	virt-manager
	virt-v2v
	virt-viewer
	wireguard-tools
)

#Add COPRs
log "Adding COPRs and installing layered packages..."

# ublue-os/packages: uupd and ublue-polkit-rules
dnf -y copr enable ublue-os/packages

# karmab/kcli: kcli
dnf -y copr enable karmab/kcli

# librewolf
curl -fsSL https://repo.librewolf.net/librewolf.repo | tee /etc/yum.repos.d/librewolf.repo

# gmaglione/podman-bootc: podman-bootc
dnf -y copr enable gmaglione/podman-bootc

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

dnf5 -y upgrade --enablerepo=updates-testing --refresh --advisory=FEDORA-2025-c358833c5d

dnf -y swap \
	--repo="terra, terra-extras" \
	gnome-shell gnome-shell

dnf versionlock add gnome-shell

dnf -y swap \
	--repo="terra, terra-extras" \
	switcheroo-control switcheroo-control

dnf versionlock add switcheroo-control

log "Layered packages installed."

# Disable all repos
for i in /etc/yum.repos.d/*.repo; do
	sed -i 's@enabled=1@enabled=0@g' "$i"
done

dnf clean all
