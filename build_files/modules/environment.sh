#!/bin/bash

set -euo pipefail
[[ -n "${SET_X:-}" ]] && set -x

trap '[[ ! $BASH_COMMAND =~ ^(echo|log) ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

# Enable Stem Darkening
echo 'FREETYPE_PROPERTIES="cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"' | sudo tee -a /etc/environment > /dev/null

# Copy Flatpak
rsync -av --no-times /ctx/repo_files/flatpaks /etc/ublue-os/flatpaks.list

# Custom just commands
mkdir -p /tmp/just
cat /ctx/repo_files/just/*.just > /tmp/just/99-custom.just
mv /tmp/just/99-custom.just /usr/share/ublue-os/just/
chmod 644 /usr/share/ublue-os/just/99-custom.just
echo 'import "/usr/share/ublue-os/just/99-custom.just"' | sudo tee -a /usr/share/ublue-os/justfile > /dev/null
rm -rf /tmp/just

# Remove stock desktop icons
rm -rf /usr/share/applications/discourse.desktop
rm -rf /usr/share/applications/documentation.desktop
rm -rf /usr/share/applications/system-update.desktop
rm -rf /usr/share/applications/org.freedesktop.MalcontentControl.desktop
update-desktop-database

# Get WhiteSur Cursors and Icons
mkdir -p /tmp/WhiteSur-icons
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icons
/tmp/WhiteSur-icons/install.sh -a -b -d '/usr/share/icons'
rm -rf /tmp/WhiteSur-icons

mkdir -p /tmp/WhiteSur-cursors
git clone https://github.com/vinceliuice/WhiteSur-cursors.git /tmp/WhiteSur-cursors
mkdir -p /usr/share/icons/WhiteSur-cursors
cp -r /tmp/WhiteSur-cursors/dist/* /usr/share/icons/WhiteSur-cursors
rm -rf /tmp/WhiteSur-icons

FONTS_DIR="/usr/share/fonts"

# Apple Color Emoji
mkdir -p ${FONTS_DIR}/apple-color-emoji
wget https://github.com/samuelngs/apple-emoji-linux/releases/latest/download/AppleColorEmoji.ttf -O ${FONTS_DIR}/apple-color-emoji/AppleColorEmoji.ttf

# Remove Google Noto Emoji as it'll override everything
rm -rf /usr/share/fonts/google-noto-color-emoji-fonts

# Github Monaspace
mkdir -p /tmp/fonts
git clone https://github.com/githubnext/monaspace.git /tmp/fonts
mkdir -p ${FONTS_DIR}/monaspace
cp -r /tmp/fonts/fonts/otf/* ${FONTS_DIR}/monaspace
rm -rf /tmp/fonts

# Custom Fonts (SF Pro, MSFT)
if [ -n "$REMOTE_FONTS_URL" ]; then
  wget -O ${FONTS_DIR}/fonts.tar.xz $REMOTE_FONTS_URL
  tar -xvJf ${FONTS_DIR}/fonts.tar.xz -C ${FONTS_DIR}/
  rm ${FONTS_DIR}/fonts.tar.xz
fi

fc-cache -fv