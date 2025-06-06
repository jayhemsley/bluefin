# vim: set ft=make :

check-idle-power-draw:
    #!/usr/bin/bash
    run0 powerstat -a -r

# Configure Bluetooth headset profile
configure-bluetooth-headset-profile ACTION="prompt":
    #!/usr/bin/run0 /usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_STATE="Enabled (Default)"
    FILE_CONF="/usr/share/ublue-os/custom/51-disable-bluetooth-headphone-profile-switch.conf"
    WIREPLUMBER_DIR="/etc/wireplumber/wireplumber.conf.d"
    WIREPLUMBER_FILE="51-disable-bluetooth-headphone-profile-switch.conf"
    if [ -f "${WIREPLUMBER_DIR}/${WIREPLUMBER_FILE}" ]; then
      CURRENT_STATE="Disabled"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "prompt" ]; then
    echo "${bold}Configuring Bluetooth headset profile behavior${normal}"    
    echo "Bluetooth headset profile is currently: ${bold}${CURRENT_STATE}${normal}"
    echo 'Disabling Bluetooth headset profile can be useful if you do not use mic from Bluetooth headphones & want to avoid lower audio quality from sudden headset profile switch.'
    echo 'Enable or Disable Bluetooth headset profile? Press ESC to exit.'
    OPTION=$(ugum choose "Enable (Default)" Disable)
    elif [ "$OPTION" == "help" ]; then
      echo "Usage: just configure-bluetooth-headset-profile <option>"
      echo "  <option>: Specify the quick option - 'disable' or 'enable'"
      echo "  Use 'disable' to disable Bluetooth headset profile."
      echo "  Use 'enable' to revert to defaults."
      exit 0
    fi    
    if [ "${OPTION,,}" == "disable" ]; then
      if ! [ -f "${WIREPLUMBER_DIR}/${WIREPLUMBER_FILE}" ]; then
        mkdir -p "${WIREPLUMBER_DIR}"
        cp "${FILE_CONF}" "${WIREPLUMBER_DIR}/${WIREPLUMBER_FILE}"
        systemctl --user restart wireplumber
          echo 'Disable Bluetooth headset profile setting applied.'
      else
        printf "\e[1;31mERROR: Bluetooth headset profile is already disabled, no change is made.\e[0m\n" 1>&2
      fi  
    elif [ "$OPTION" == "Enable (Default)" ] || [ "${OPTION,,}" == "enable" ]; then
      if [ $(find "${WIREPLUMBER_DIR}" -type f | wc -l) -eq 1 ] && [ -f "${WIREPLUMBER_DIR}/${WIREPLUMBER_FILE}" ]; then
        rm -r "${WIREPLUMBER_DIR}"
        systemctl --user restart wireplumber
          echo 'Reverted setting "Bluetooth headset profile" to defaults.'
      elif [ -f "${WIREPLUMBER_DIR}/${WIREPLUMBER_FILE}" ]; then
        rm "${WIREPLUMBER_DIR}/${WIREPLUMBER_FILE}"
        systemctl --user restart wireplumber
          echo 'Reverted setting "Bluetooth headset profile" to defaults (Enabled).'
      elif [ ! -f "${WIREPLUMBER_DIR}/${WIREPLUMBER_FILE}" ]; then
        printf "\e[1;31mERROR: Bluetooth headset profile is already enabled, no change is made.\e[0m\n" 1>&2
      fi
    fi