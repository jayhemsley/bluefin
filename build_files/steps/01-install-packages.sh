FONTSINSTALL_PACKAGES=(
	android-tools
	btrfs-assistant
	edk2-ovmf
	fzf
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
	solaar-udev
	tmux
	v4l-utils
	virt-install
	virt-manager
	virt-v2v
	virt-viewer
	wireguard-tools
)

log "Adding COPRs and installing layered packages..."

# kcli
dnf -y copr enable karmab/kcli

# librewolf
curl -fsSL https://repo.librewolf.net/librewolf.repo | tee /etc/yum.repos.d/librewolf.repo

# podman-bootc
dnf -y copr enable gmaglione/podman-bootc

# terra
dnf -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
dnf -y install terra-release-extras || true
dnf config-manager setopt "terra*".enabled=0

for repo in /etc/yum.repos.d/*.repo; do
	sed -i 's/metalink?/metalink?protocol=https\&/g' "$repo"
done

dnf install --setopt=install_weak_deps=False -y "${LAYERED_PACKAGES[@]}"

dnf5 -y upgrade --enablerepo=updates-testing --refresh --advisory=FEDORA-2025-c358833c5d

# Enable Terra repo (Extras does not exist on F40)
# shellcheck disable=SC2016
dnf -y swap \
	--repo="terra, terra-extras" \
	gnome-shell gnome-shell

dnf versionlock add gnome-shell

dnf -y swap \
	--repo="terra, terra-extras" \
	switcheroo-control switcheroo-control

dnf versionlock add switcheroo-control

log "Layered packages installed."

for i in /etc/yum.repos.d/*.repo; do
	sed -i 's@enabled=1@enabled=0@g' "$i"
done

dnf clean all
