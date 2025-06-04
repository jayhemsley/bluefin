# Signing
mkdir -p /etc/containers
mkdir -p /etc/pki/containers
mkdir -p /etc/containers/registries.d/

# TODO: Remove when things like uCore stops using /usr/etc for their policy.json
# Also remove all the other relations to /usr/etc
if [ -f /usr/etc/containers/policy.json ]; then
    cp /usr/etc/containers/policy.json /etc/containers/policy.json
fi

cat <<<"$(jq '.transports.docker |=. + {
   "ghcr.io/jayhemsley": [
    {
        "type": "sigstoreSigned",
        "keyPaths": [
            "/etc/pki/containers/jayhemsley.pub"
        ],
        "signedIdentity": {
            "type": "matchRepository"
        }
    }
]}' <"/etc/containers/policy.json")" >"/tmp/policy.json"

cp /tmp/policy.json /etc/containers/policy.json
cp /ctx/cosign.pub /etc/pki/containers/jayhemsley.pub

tee /etc/containers/registries.d/jayhemsley.yaml <<EOF
docker:
  ghcr.io/jayhemsley:
    use-sigstore-attachments: true
EOF

mkdir -p /usr/etc/containers/
cp /etc/containers/policy.json /usr/etc/containers/policy.json