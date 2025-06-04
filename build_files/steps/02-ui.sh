# Enable Stem Darkening
echo 'FREETYPE_PROPERTIES="cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"' | sudo tee -a /etc/environment >/dev/null

log "Install WhiteSur icons and cursors systemwide"

mkdir -p /tmp/WhiteSur-icons
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icons
/tmp/WhiteSur-icons/install.sh -a -b -d '/usr/share/icons'
rm -rf /tmp/WhiteSur-icons

mkdir -p /tmp/WhiteSur-cursors
git clone https://github.com/vinceliuice/WhiteSur-cursors.git /tmp/WhiteSur-cursors
mkdir -p /usr/share/icons/WhiteSur-cursors
cp -r /tmp/WhiteSur-cursors/dist/* /usr/share/icons/WhiteSur-cursors
rm -rf /tmp/WhiteSur-icons

log "Install adw-gtk3 to skel"

VER=$(basename $(curl -Ls -o /dev/null -w %{url_effective} https://github.com/lassekongo83/adw-gtk3/releases/latest)) && curl -fLs --create-dirs https://github.com/lassekongo83/adw-gtk3/releases/download/${VER}/adw-gtk3${VER}.tar.xz -o /tmp/adw-gtk3.tar.gz
mkdir -p /etc/skel/.local/share/themes/ && tar -xf /tmp/adw-gtk3.tar.gz -C /etc/skel/.local/share/themes/
rm /tmp/adw-gtk3.tar.gz

log "Install systemwide fonts..."

FONTS_DIR="/usr/share/fonts"

mkdir -p ${FONTS_DIR}/apple-color-emoji
wget https://github.com/samuelngs/apple-emoji-linux/releases/latest/download/AppleColorEmoji.ttf -O ${FONTS_DIR}/apple-color-emoji/AppleColorEmoji.ttf

rm -rf /usr/share/fonts/google-noto-color-emoji-fonts

mkdir -p /tmp/fonts
git clone https://github.com/githubnext/monaspace.git /tmp/fonts
mkdir -p ${FONTS_DIR}/monaspace
cp -r /tmp/fonts/fonts/otf/* ${FONTS_DIR}/monaspace
rm -rf /tmp/fonts

wget -O ${FONTS_DIR}/fonts.tar.xz https://linux.hemsley.dev/019733d3-970c-7168-978d-523401ccbe3a-fonts.tar.xz
tar -xvJf ${FONTS_DIR}/fonts.tar.xz -C ${FONTS_DIR}/
rm ${FONTS_DIR}/fonts.tar.xz

fc-cache -fv
