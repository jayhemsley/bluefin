# vim: set ft=make :
########################
### custom.just
### Some additional ones from secureblue etc
########################
## Standardized verbs
# configure- = configure something that is pre-installed on the image
# install-   = install something, no uninstall or configuration provided
# setup-     = install something and also provide configuration and/or uninstallation options
# toggle-    = turn something on/off, logic can be automatic or manual selection
# fix-       = apply fix/patch/workaround for something
# foo        = no verb is used for shortcuts or something deemed important enough to use a super memorable name

# Setup General Environment
[group('Personal')]
setup-environment:
  #!/usr/bin/env bash
  source /usr/lib/ujust/ujust.sh

  # Removing default flatpaks
  DEFAULT_FLATPAKS=(
    com.github.Matoking.protontricks
    org.fedoraproject.MediaWriter
    org.gnome.baobab
    org.gnome.Calculator
    org.gnome.Calendar
    org.gnome.Characters
    org.gnome.Connections
    org.gnome.Contacts
    org.gnome.clocks
    org.gnome.Snapshot
    org.gnome.Evince
    org.gnome.Extensions
    org.gnome.Logs
    org.gnome.Loupe
    org.gnome.font-viewer
    org.gnome.Maps
    org.gnome.Weather
  )

  for package in "${DEFAULT_FLATPAKS[@]}"; do
    echo "Removing Flatpak package: $package"
    flatpak uninstall -y "$package"
  done

  flatpak uninstall --unused -y

  echo "All default packages have been removed. Installing system flatpaks..."

  ujust install-system-flatpaks

  echo "Flatpaks installed!"

  echo "Setting up theming"

  REPO="lassekongo83/adw-gtk3"
  
  echo "Fetching the latest release tarball URL from GitHub..."
  
  LATEST_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r '.assets[] | select(.name | test("adw-gtk3.*\\.tar\\.xz")) | .browser_download_url')

  if [ -z "$LATEST_URL" ]; then
    echo "Error: Could not find the latest tarball URL."
    exit 1
  fi

  TMP_DIR="/tmp/adw-gtk3"
  THEME_DIR="$HOME/.local/share/themes"
  TARBALL="$TMP_DIR/adw-gtk3.tar.xz"

  echo "Downloading the latest tarball from $LATEST_URL..."
  mkdir -p "$TMP_DIR"
  curl -L "$LATEST_URL" -o "$TARBALL"

  echo "Extracting the tarball in /tmp..."
  mkdir -p "$TMP_DIR/extracted"
  tar -xf "$TARBALL" -C "$TMP_DIR/extracted"

  echo "Moving all extracted theme folders to the final destination..."
  cp -r $TMP_DIR/extracted/* $THEME_DIR

  echo "Setting GNOME theme and color scheme..."

  echo "Cleaning up the downloaded tarball and temporary files..."
  rm -rf "$TMP_DIR"

  echo "Applying flatpak overrides..."
  sudo flatpak override --filesystem=xdg-data/themes
  sudo flatpak mask org.gtk.Gtk3theme.adw-gtk3
  sudo flatpak mask org.gtk.Gtk3theme.adw-gtk3-dark

  ujust setup-brew-not-found
  ujust update-firmware

  echo "Environment has been setup."

# Toggle the cups service on/off
[group('System')]
toggle-cups:
  #!/usr/bin/env bash
  source /usr/lib/ujust/ujust.sh

  if systemctl is-enabled --quiet cups; then
    firewall-cmd --permanent --remove-port=631/tcp
    firewall-cmd --permanent --remove-port=631/udp
    firewall-cmd --reload
    systemctl mask cups
    systemctl disable cups
    systemctl stop cups
    systemctl daemon-reload
    echo "CUPS disabled."
  else
    firewall-cmd --permanent --add-port=631/tcp
    firewall-cmd --permanent --add-port=631/udp
    firewall-cmd --reload
    systemctl unmask cups
    systemctl enable cups
    systemctl start cups
    systemctl daemon-reload
    echo "CUPS enabled."
    echo "Note: cups-browsed, the printer discovery service, is still disabled for security reasons. New network printers will need to be added manually."
  fi

# Setup USBGuard
[group('System')]
setup-usbguard:
  #!/usr/bin/env bash
  source /usr/lib/ujust/ujust.sh

  echo "Notice: This will generate a policy based on your existing connected USB devices."

  # shellcheck disable=SC2016

  sudo sh -c '
    mkdir -p /var/log/usbguard
    mkdir -p /etc/usbguard
    chmod 755 /etc/usbguard
    groupadd usbguard
    usermod -aG usbguard "$SUDO_USER"
    usbguard generate-policy > /etc/usbguard/rules.conf
    sed -i "/IPCAllowedGroups=wheel/s/\$/ usbguard/" /etc/usbguard/usbguard-daemon.conf
    restorecon -vR /var/log/usbguard
    systemctl enable --now usbguard.service
    usbguard add-user "$SUDO_USER"
  '
  if ! rpm-ostree status | grep '●' | grep -q 'securecore'; then
    systemctl enable --user --now usbguard-notifier.service
  fi

# Update Firmwares
[group('System')]
update-firmware:
  #!/usr/bin/env bash
  source /usr/lib/ujust/ujust.sh
  
  fwupdmgr refresh --force
  fwupdmgr get-updates
  fwupdmgr update
