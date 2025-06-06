#####
## Install GNOME Extensions
#####

# Credit @fiftydinar (https://github.com/fiftydinar)
# https://github.com/fiftydinar/gidro-os/blob/main/modules/gnome-extensions-unverified/gnome-extensions-unverified.sh

INSTALL_GNOME_EXTENSIONS_PKIDS=(
	# Use PKIDs
	4269 # Alphabetical App Grid
	6670 # Bluetooth Battery Meter
	2645 # Brightness Control Using ddcutil
	4679 # Burn My Windows
	3396 # Color Picker
	3740 # Compiz Alike Magic Lamp Effect
	6242 # Emoji Copy
	3956 # GNOME Fuzzy App Search
	36 # Lock Keys
	5964 # Quick Settings Audio Devices Hider
	6000 # Quick Settings Audio Devices Renamer
	4691 # PIP on Top
	5090 # Space Bar
	7065 # Tiling Shell
	6281 # Wallpaper Slideshow
)

if [[ ${#INSTALL_GNOME_EXTENSIONS_PKIDS[@]} -lt 1 ]]; then
  log "ERROR: You did not specify the extension to install in module recipe file"
  exit 1
fi

if ! command -v gnome-shell &> /dev/null; then 
  log "ERROR: Your custom image is using non-Gnome desktop environment, where Gnome extensions are not supported"
  exit 1
fi

log "Testing connection with https://extensions.gnome.org/..."
if ! curl --output /dev/null --silent --head --fail "https://extensions.gnome.org/"; then
  log "ERROR: Connection unsuccessful."
  log "       This usually happens when https://extensions.gnome.org/ website is down."
  log "       Please try again later (or disable the module temporarily)"
  exit 1
else
  log "Connection successful, proceeding."
fi  


GNOME_VER=$(gnome-shell --version | sed 's/[^0-9]*\([0-9]*\).*/\1/')
log "Gnome version: ${GNOME_VER}"

for INSTALL_EXT in "${INSTALL_GNOME_EXTENSIONS_PKIDS[@]}"; do
		# PK ID extension config fallback if specified
		URL_QUERY=$(curl -sf "https://extensions.gnome.org/extension-info/?pk=${INSTALL_EXT}")
		PK_EXT=$(log "${URL_QUERY}" | jq -r '.["pk"]' 2>/dev/null)
		if [[ -z "${PK_EXT}" ]] || [[ "${PK_EXT}" == "null" ]]; then
			log "ERROR: Extension with PK ID '${INSTALL_EXT}' does not exist in https://extensions.gnome.org/ website"
			log "       Please assure that you typed the PK ID correctly,"
			log "       and that it exists in Gnome extensions website"
			exit 1
		fi
		EXT_UUID=$(log "${URL_QUERY}" | jq -r '.["uuid"]')
		EXT_NAME=$(log "${URL_QUERY}" | jq -r '.["name"]')
		# Gets latest extension version for latest available Gnome version
		SUITABLE_VERSION=$(log "${URL_QUERY}" | jq -r '.shell_version_map | to_entries | max_by(.key | tonumber) | .value.version')

    # Removes every @ symbol from UUID, since extension URL doesn't contain @ symbol
    URL="https://extensions.gnome.org/extension-data/${EXT_UUID//@/}.v${SUITABLE_VERSION}.shell-extension.zip"
    TMP_DIR="/tmp/${EXT_UUID}"
    ARCHIVE=$(basename "${URL}")
    ARCHIVE_DIR="${TMP_DIR}/${ARCHIVE}"
    log "Installing '${EXT_NAME}' Gnome extension with version ${SUITABLE_VERSION}"
    # Download archive
    log "Downloading ZIP archive ${URL}"
    curl -fLs --create-dirs "${URL}" -o "${ARCHIVE_DIR}"
    log "Downloaded ZIP archive ${URL}"
    # Extract archive
    log "Extracting ZIP archive"
    unzip "${ARCHIVE_DIR}" -d "${TMP_DIR}" > /dev/null
    # Remove archive
    log "Removing archive"
    rm "${ARCHIVE_DIR}"
    # Install main extension files
    log "Installing main extension files"
    install -d -m 0755 "/usr/share/gnome-shell/extensions/${EXT_UUID}/"
    find "${TMP_DIR}" -mindepth 1 -maxdepth 1 ! -path "*locale*" ! -path "*schemas*" -exec cp -r {} "/usr/share/gnome-shell/extensions/${EXT_UUID}/" \;
    find "/usr/share/gnome-shell/extensions/${EXT_UUID}" -type d -exec chmod 0755 {} +
    find "/usr/share/gnome-shell/extensions/${EXT_UUID}" -type f -exec chmod 0644 {} +
    # Install schema
    if [[ -d "${TMP_DIR}/schemas" ]]; then
      log "Installing schema extension file"
      # Workaround for extensions, which explicitly require compiled schema to be in extension UUID directory (rare scenario due to how extension is programmed in non-standard way)
      # Error code example:
      # GLib.FileError: Failed to open file “/usr/share/gnome-shell/extensions/flypie@schneegans.github.com/schemas/gschemas.compiled”: open() failed: No such file or directory
      # If any extension produces this error, it can be added in if statement below to solve the problem
      # Fly-Pie or PaperWM
      if [[ "${EXT_UUID}" == "flypie@schneegans.github.com" || "${EXT_UUID}" == "paperwm@paperwm.github.com" ]]; then
        install -d -m 0755 "/usr/share/gnome-shell/extensions/${EXT_UUID}/schemas/"
        install -D -p -m 0644 "${TMP_DIR}/schemas/"*.gschema.xml "/usr/share/gnome-shell/extensions/${EXT_UUID}/schemas/"
        glib-compile-schemas "/usr/share/gnome-shell/extensions/${EXT_UUID}/schemas/" &>/dev/null
      else
        # Regular schema installation
        install -d -m 0755 "/usr/share/glib-2.0/schemas/"
        install -D -p -m 0644 "${TMP_DIR}/schemas/"*.gschema.xml "/usr/share/glib-2.0/schemas/"
      fi  
    fi  
    # Install languages
    # Locale is not crucial for extensions to work, as they will fallback to gschema.xml
    # Some of them might not have any locale at the moment
    # So that's why I made a check for directory
    # I made an additional check if language files are available, in case if extension is packaged with an empty folder, like with Default Workspace extension
    if [[ -d "${TMP_DIR}/locale/" ]]; then
      if find "${TMP_DIR}/locale/" -type f -name "*.mo" -print -quit | read; then
        log "Installing language extension files"
        install -d -m 0755 "/usr/share/locale/"
        cp -r "${TMP_DIR}/locale"/* "/usr/share/locale/"
      fi
    fi
    # Modify metadata.json to support latest Gnome version
    log "Modifying metadata.json to support Gnome ${GNOME_VER}"      
    jq --arg gnome_ver "${GNOME_VER}" 'if (.["shell-version"] | index($gnome_ver) | not) then .["shell-version"] += [$gnome_ver] else . end' "/usr/share/gnome-shell/extensions/${EXT_UUID}/metadata.json" > "/tmp/temp-metadata.json"
    mv "/tmp/temp-metadata.json" "/usr/share/gnome-shell/extensions/${EXT_UUID}/metadata.json"
    # Delete the temporary directory
    log "Cleaning up the temporary directory"
    rm -r "${TMP_DIR}"
    log "Extension '${EXT_NAME}' is successfully installed"
    log "----------------------------------INSTALLATION DONE----------------------------------"
done

# Compile gschema to include schemas from extensions  & to refresh the schema state
log "Compiling gschema to include extension schemas & to refresh the schema state"
glib-compile-schemas "/usr/share/glib-2.0/schemas/" &>/dev/null