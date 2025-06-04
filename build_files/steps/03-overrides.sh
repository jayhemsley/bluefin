# GSchema Overrides
# By @bsherman (https://github.com/bsherman)
# https://github.com/bsherman/bos/blob/main/desktop-changes.sh

log "Generate default schemas"

mkdir -p /tmp/ublue-schema-test &&
	find /usr/share/glib-2.0/schemas/ -type f ! -name "*.gschema.override" -exec cp {} /tmp/ublue-schema-test/ \; &&
	cp /usr/share/glib-2.0/schemas/*-secureblue.gschema.override /tmp/ublue-schema-test/ &&
	echo "Running error test for bos gschema override. Aborting if failed." &&
	glib-compile-schemas --strict /tmp/ublue-schema-test || exit 1 &&
	echo "Compiling gschema to include our overrides" &&
	glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

log "Remove avif thumbnailer, as HEIF thumbnailer already covers it"
rm /usr/share/thumbnailers/avif.thumbnailer

log "Disable general usage of package managers."

PACKAGE_MANAGERS=(
	"/usr/bin/dnf"
	"/usr/bin/dnf5"
	"/usr/bin/yum"
)

for MGR in "${PACKAGE_MANAGERS[@]}"; do
	cat <<EOF >"${MGR}"
    #!/usr/bin/env bash

    echo "Package/application layering is disabled."
EOF
done

# Enable experimental Bluetooth features to make it more compatible with Bluetooth Battery Meter extension
sed -i 's/#Experimental = false/Experimental = true/; s/#Experimental = true/Experimental = true/; s/Experimental = false/Experimental = true/; s/#KernelExperimental = false/KernelExperimental = true/; s/#KernelExperimental = true/KernelExperimental = true/; s/KernelExperimental = false/KernelExperimental = true/; s/#Experimental=false/Experimental = true/; s/#Experimental=true/Experimental = true/; s/Experimental=false/Experimental = true/; s/#KernelExperimental=false/KernelExperimental = true/; s/#KernelExperimental=true/KernelExperimental = true/; s/KernelExperimental=false/KernelExperimental = true/' /etc/bluetooth/main.conf
