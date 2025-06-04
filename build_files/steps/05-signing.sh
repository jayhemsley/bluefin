CONTAINER_DIR="/usr/etc/containers"
ETC_CONTAINER_DIR="/etc/containers"
IMAGE_REGISTRY_TITLE=$(echo "${IMAGE_REGISTRY}" | cut -d'/' -f2-)

log "Setting up container signing in policy.json for $IMAGE_NAME"
log "Registry to write: $IMAGE_REGISTRY"

for dir in "$CONTAINER_DIR" "$ETC_CONTAINER_DIR"; do
    mkdir -p "$dir/registries.d"
done
for dir in "/usr/etc/pki/containers" "/etc/pki/containers"; do
    mkdir -p "$dir"
done

# Use cosign.pub from repo root
PUBKEY_SOURCE="/ctx/cosign.pub"
PUBKEY_DEST="/usr/etc/pki/containers/${IMAGE_REGISTRY_TITLE}.pub"
cp "$PUBKEY_SOURCE" "$PUBKEY_DEST"
cp "$PUBKEY_SOURCE" "/etc/pki/containers/${IMAGE_REGISTRY_TITLE}.pub"

# Merge or add to policy.json
for POLICY_FILE in "$CONTAINER_DIR/policy.json" "$ETC_CONTAINER_DIR/policy.json"; do
    if [[ -f "$POLICY_FILE" ]]; then
        # Merge new rule into existing policy.json
        jq --arg image_registry "${IMAGE_REGISTRY}" \
           --arg image_registry_title "${IMAGE_REGISTRY_TITLE}" \
           '.transports.docker[$image_registry] = [
                {
                    "type": "sigstoreSigned",
                    "keyPath": ("/usr/etc/pki/containers/" + $image_registry_title + ".pub"),
                    "signedIdentity": { "type": "matchRepository" }
                }
            ] | .' "$POLICY_FILE" > POLICY.tmp
        mv POLICY.tmp "$POLICY_FILE"
    else
        # Create a minimal policy.json if missing
        jq -n --arg image_registry "${IMAGE_REGISTRY}" \
              --arg image_registry_title "${IMAGE_REGISTRY_TITLE}" \
              '{
                  "default": [{"type": "reject"}],
                  "transports": {
                      "docker": {
                          ($image_registry): [
                              {
                                  "type": "sigstoreSigned",
                                  "keyPath": ("/usr/etc/pki/containers/" + $image_registry_title + ".pub"),
                                  "signedIdentity": { "type": "matchRepository" }
                              }
                          ]
                      }
                  }
              }' > "$POLICY_FILE"
    fi
done

log "Container signing policy updated for $IMAGE_REGISTRY"