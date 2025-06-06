#!/bin/bash
#####
## Install GNOME Extensions
#####
log() {
	echo "=== $* ==="
}

# Credit @fiftydinar (https://github.com/fiftydinar)
# https://github.com/fiftydinar/gidro-os/blob/main/modules/gnome-extensions-unverified/gnome-extensions-unverified.sh

INSTALL_GNOME_EXTENSIONS=(
	AlphabeticalAppGrid@stuarthayhurst
	Bluetooth-Battery-Meter@maniacx.github.com
	display-brightness-ddcutil@themightydeity.github.com
	burn-my-windows@schneegans.github.com
	color-picker@tuberry
	compiz-alike-magic-lamp-effect@hermes83.github.com
	emoji-copy@felipeftn
	gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com
	lockkeys@vaina.lt
	quicksettings-audio-devices-hider@marcinjahn.com
	quicksettings-audio-devices-renamer@marcinjahn.com
	pip-on-top@rafostar.github.com
	space-bar@luchrioh
	tilingshell@ferrarodomenico.com
	azwallpaper@azwallpaper.gitlab.com
)

if [[ ${#INSTALL_GNOME_EXTENSIONS[@]} -lt 1 ]]; then
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

for INSTALL_EXT in "${INSTALL_GNOME_EXTENSIONS[@]}"; do
    if [[ ! "${INSTALL_EXT}" =~ ^[0-9]+$ ]]; then
      # Literal-name extension config
      # Replaces whitespaces with %20 for install entries which contain extension name, since URLs can't contain whitespace      
      WHITESPACE_HTML="${INSTALL_EXT// /%20}"
      URL_QUERY=$(curl -sf "https://extensions.gnome.org/extension-query/?search=${WHITESPACE_HTML}")
      QUERIED_EXT=$(echo "${URL_QUERY}" | jq ".extensions[] | select(.uuid == \"${INSTALL_EXT}\")")
      if [[ -z "${QUERIED_EXT}" ]] || [[ "${QUERIED_EXT}" == "null" ]]; then
        log "ERROR: Extension '${INSTALL_EXT}' does not exist in https://extensions.gnome.org/ website"
        log "       Extension name is case-sensitive, so be sure that you typed it correctly,"
        log "       including the correct uppercase & lowercase characters"
        exit 1
      fi
      readarray -t EXT_UUID < <(echo "${QUERIED_EXT}" | jq -r '.["uuid"]')
      readarray -t EXT_NAME < <(echo "${QUERIED_EXT}" | jq -r '.["name"]')
      if [[ ${#EXT_UUID[@]} -gt 1 ]] || [[ ${#EXT_NAME[@]} -gt 1 ]]; then
        log "ERROR: Multiple compatible Gnome extensions with the same name are found, which this module cannot select"
        log "       To solve this problem, please use PK ID as a module input entry instead of the extension name"
        log "       You can get PK ID from the extension URL, like from Blur my Shell's 3193 PK ID example below:"
        log "       https://extensions.gnome.org/extension/3193/blur-my-shell/"
        exit 1
      fi        
      # Gets latest extension version for latest available Gnome version
				SUITABLE_VERSION=$(echo "${QUERIED_EXT}" | jq -r '
				.shell_version_map
				| to_entries
				| map(select(.value.version != null))
				| max_by(.key | capture("(?<major>[0-9]+)(\\.(?<minor>[0-9]+))?").major | tonumber)
				| .value.version
			')
    else
      # PK ID extension config fallback if specified
      URL_QUERY=$(curl -sf "https://extensions.gnome.org/extension-info/?pk=${INSTALL_EXT}")
      PK_EXT=$(echo "${URL_QUERY}" | jq -r '.["pk"]' 2>/dev/null)
      if [[ -z "${PK_EXT}" ]] || [[ "${PK_EXT}" == "null" ]]; then
        log "ERROR: Extension with PK ID '${INSTALL_EXT}' does not exist in https://extensions.gnome.org/ website"
        log "       Please assure that you typed the PK ID correctly,"
        log "       and that it exists in Gnome extensions website"
        exit 1
      fi
      EXT_UUID=$(echo "${URL_QUERY}" | jq -r '.["uuid"]')
      EXT_NAME=$(echo "${URL_QUERY}" | jq -r '.["name"]')
      # Gets latest extension version for latest available Gnome version
      SUITABLE_VERSION=$(echo "${URL_QUERY}" | jq -r '.shell_version_map | to_entries | max_by(.key | tonumber) | .value.version')
    fi  
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