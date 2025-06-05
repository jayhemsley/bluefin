# vim: set ft=make :

alias upgrade := update

# Update system, flatpaks, and containers all at once
update:
    #!/usr/bin/bash
    SERVICE="rpm-ostreed-automatic.service"

    if systemctl is-active --quiet "$SERVICE"; then
        echo "automatic updates are currently running, use \`journalctl -fexu $SERVICE\` to see logs"
        exit 1
    fi

    # rpm-ostree used due to bootc upgrade not supporting local layered packages
    rpm-ostree upgrade

    # Updates system Flatpaks
    if flatpak remotes | grep -q system; then
        flatpak update -y
    fi

    # Update user Flatpaks
    if flatpak remotes | grep -q user; then
        flatpak update --user -y
    fi

    # Guard Brew if the user does not own brew/doesn't exist
    if [[ -O /var/home/linuxbrew/.linuxbrew/bin/brew ]]; then
        # Upgrade will run brew update if needed
        /var/home/linuxbrew/.linuxbrew/bin/brew upgrade
    fi

alias auto-update := toggle-updates

# Turn automatic updates on or off
toggle-updates ACTION="prompt":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    CURRENT_STATE="Disabled"
    if systemctl is-enabled -q rpm-ostreed-automatic.timer; then
        CURRENT_STATE="Enabled"
    fi
    OPTION={{ ACTION }}
    if [ "$OPTION" == "prompt" ]; then
        echo "Automatic updates are currently: ${bold}${CURRENT_STATE}${normal}"
        echo "Enable or Disable automatic updates?"
        OPTION=$(ugum choose Enable Disable)
    elif [ "$OPTION" == "help" ]; then
        echo "Usage: ujust toggle-updates <option>"
        echo "  <option>: Specify the quick option - 'enable' or 'disable'"
        echo "  Use 'enable' to Enable automatic updates."
        echo "  Use 'disable' to Disable automatic updates."
        exit 0
    fi
    TIMER="rpm-ostreed-automatic.timer"
    if [ "${OPTION,,}" == "enable" ]; then
        run0 systemctl enable "$TIMER"
    elif [ "${OPTION,,}" == "disable" ]; then
        run0 systemctl disable "$TIMER"
    fi
