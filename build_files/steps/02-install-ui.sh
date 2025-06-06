#####
## Add components for the desktop experience.
#####

# WhiteSur Icons
log "Install WhiteSur icons and cursors systemwide"

mkdir -p /tmp/WhiteSur-icons
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icons
/tmp/WhiteSur-icons/install.sh -a -b -d '/usr/share/icons'
rm -rf /tmp/WhiteSur-icons

# WhiteSur Cursors
mkdir -p /tmp/WhiteSur-cursors
git clone https://github.com/vinceliuice/WhiteSur-cursors.git /tmp/WhiteSur-cursors
mkdir -p /usr/share/icons/WhiteSur-cursors
cp -r /tmp/WhiteSur-cursors/dist/* /usr/share/icons/WhiteSur-cursors
rm -rf /tmp/WhiteSur-icons

# Install adw-gtk3 so it's available as a local theme (for full flatpak compatibility)
# log "Install adw-gtk3 to skel"

# VER=$(basename $(curl --retry 3 -Ls -o /dev/null -w %{url_effective} https://github.com/lassekongo83/adw-gtk3/releases/latest)) && curl --retry 3 -fLs --create-dirs https://github.com/lassekongo83/adw-gtk3/releases/download/${VER}/adw-gtk3${VER}.tar.xz -o /tmp/adw-gtk3.tar.gz
# mkdir -p /etc/skel/.local/share/themes/ && tar -xf /tmp/adw-gtk3.tar.gz -C /etc/skel/.local/share/themes/
# rm /tmp/adw-gtk3.tar.gz

# Install fonts systemwide: Apple Color Emoji, Monaspace, SF Pro and Microsoft Fonts
log "Install systemwide fonts..."

FONTS_DIR="/usr/share/fonts"

# mkdir -p ${FONTS_DIR}/apple-color-emoji
# curl --retry 3 -Lo ${FONTS_DIR}/apple-color-emoji/AppleColorEmoji.ttf "https://github.com/samuelngs/apple-emoji-linux/releases/latest/download/AppleColorEmoji.ttf"

DOWNLOAD_URL=$(curl --retry 3 https://api.github.com/repos/githubnext/monaspace/releases/latest | jq -r '.assets[] | select(.name| test(".*.zip$")).browser_download_url')
curl --retry 3 -Lo /tmp/monaspace-font.zip "$DOWNLOAD_URL"

unzip -qo /tmp/monaspace-font.zip -d /tmp/monaspace-font
mkdir -p /usr/share/fonts/monaspace
mv /tmp/monaspace-font/monaspace-v*/fonts/otf/* /usr/share/fonts/monaspace/
rm -rf /tmp/monaspace-font*

curl --retry 3 -Lo ${FONTS_DIR}/fonts.tar.xz "https://linux.hemsley.dev/019733d3-970c-7168-978d-523401ccbe3a-fonts.tar.xz"
tar -xvJf ${FONTS_DIR}/fonts.tar.xz -C ${FONTS_DIR}/
rm ${FONTS_DIR}/fonts.tar.xz

fc-cache -fv
