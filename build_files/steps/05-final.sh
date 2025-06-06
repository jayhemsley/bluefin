#####
## Add overrides and individual removals.
#####

# Compile just files
find /usr/share/ublue-os/just -maxdepth 1 -type f -name '9*.just' -printf 'import "/usr/share/ublue-os/just/%f"\n' >> /usr/share/ublue-os/just/60-custom.just

# Disable some rpm-ostree logging
systemctl mask rpm-ostree-countme.timer

# Keep dconf files up to date.
systemctl enable dconf-update.service