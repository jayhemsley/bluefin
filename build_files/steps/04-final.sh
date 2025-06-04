# Compile just files
find /usr/share/ublue-os/just -maxdepth 1 -type f -name '9*.just' -printf 'import "/usr/share/ublue-os/just/%f"\n' >> /usr/share/ublue-os/just/60-custom.just

# Prevent Distrobox containers from being updated via the background service
if [[ "$(rpm -E %fedora)" -ge "42" ]]; then
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service
fi

systemctl mask rpm-ostree-countme.timer

if systemctl cat -- uupd.timer &> /dev/null; then
    systemctl enable uupd.timer
    systemctl mask rpm-ostreed-automatic.timer
    systemctl mask flatpak-system-update.timer
    systemctl --global mask flatpak-user-update.timer
else
    systemctl unmask rpm-ostreed-automatic.timer
    systemctl enable rpm-ostreed-automatic.timer
    systemctl unmask flatpak-system-update.timer
    systemctl enable flatpak-system-update.timer
    systemctl --global unmask flatpak-user-update.timer
    systemctl --global enable flatpak-user-update.timer
fi

systemctl enable dconf-update.service