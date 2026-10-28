#!/usr/bin/env bash
# Installs Tuwunel as a native systemd service on Debian or Ubuntu (x86_64 or
# arm64): an old PC on your LAN, or a dedicated server with a public IP.
# Run as root:
#   bash install-tuwunel.sh                      # old PC: LAN IP, LAN subnet only
#   CLIENT_CIDR=203.0.113.5/32 bash install-tuwunel.sh   # server: your IP only
# Optional: SERVER_NAME (default: detected address), TUWUNEL_VERSION.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Run as root (sudo -i)." >&2; exit 1; }
command -v apt-get >/dev/null || { echo "Debian/Ubuntu (apt) required." >&2; exit 1; }

TUWUNEL_VERSION="${TUWUNEL_VERSION:-v1.9.4}"
case "$(uname -m)" in
  x86_64) ARCH="x86_64-v1" ;;
  aarch64) ARCH="aarch64-v8" ;;
  *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac
ASSET="${TUWUNEL_VERSION}-release-all-${ARCH}-linux-gnu-tuwunel.zst"

apt-get update
apt-get install -y curl zstd ufw iproute2

# Detect the primary local address and its subnet.
lan_ip="$(ip -4 route get 1.1.1.1 | sed -n 's/.* src \([0-9.]*\).*/\1/p' | head -1)"
iface="$(ip -4 route get 1.1.1.1 | sed -n 's/.* dev \([^ ]*\).*/\1/p' | head -1)"
test -n "${lan_ip}" && test -n "${iface}"

# A routable (non-private) local address means a server with a public IP.
case "${lan_ip}" in
  10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*) is_public=0 ;;
  *) is_public=1 ;;
esac

if [ "${is_public}" -eq 1 ]; then
  : "${CLIENT_CIDR:?Public server: set CLIENT_CIDR to your IPv4 CIDR, e.g. 203.0.113.5/32}"
else
  # Private address: the interface's own subnet, e.g. 192.168.1.0/24.
  CLIENT_CIDR="${CLIENT_CIDR:-$(ip -4 route show dev "${iface}" proto kernel scope link | awk '{print $1}' | head -1)}"
fi
SERVER_NAME="${SERVER_NAME:-${lan_ip}}"

curl --fail --silent --show-error --location --retry 5 --output /tmp/tuwunel.zst \
  "https://github.com/matrix-construct/tuwunel/releases/download/${TUWUNEL_VERSION}/${ASSET}"
zstd -d -f /tmp/tuwunel.zst -o /usr/local/bin/tuwunel
chmod 0755 /usr/local/bin/tuwunel
rm -f /tmp/tuwunel.zst

if [ ! -f /root/tuwunel-registration-token ]; then
  (umask 077; head -c 30 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' > /root/tuwunel-registration-token)
fi

(umask 077; cat > /etc/tuwunel.env <<EOF
TUWUNEL_SERVER_NAME=${SERVER_NAME}
TUWUNEL_DATABASE_PATH=/var/lib/tuwunel
TUWUNEL_ADDRESS=0.0.0.0
TUWUNEL_PORT=8008
TUWUNEL_ALLOW_REGISTRATION=true
TUWUNEL_REGISTRATION_TOKEN=$(cat /root/tuwunel-registration-token)
EOF
)

cat > /etc/systemd/system/tuwunel.service <<'EOF'
[Unit]
Description=Tuwunel Matrix homeserver (native)
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=/etc/tuwunel.env
ExecStart=/usr/local/bin/tuwunel
DynamicUser=yes
StateDirectory=tuwunel
Restart=on-failure
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

# Restrict access on the host: dedicated servers have no Hetzner Cloud
# Firewall, and an old PC has none unless the router provides one.
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from "${CLIENT_CIDR}" to any port 22 proto tcp
ufw allow from "${CLIENT_CIDR}" to any port 8008 proto tcp
ufw --force enable

systemctl daemon-reload
systemctl enable --now tuwunel

for _ in $(seq 1 20); do
  if curl --fail --silent "http://127.0.0.1:8008/_matrix/client/versions" >/dev/null; then
    echo "Tuwunel is up: http://${SERVER_NAME}:8008 (allowed from ${CLIENT_CIDR})"
    echo "Registration token: /root/tuwunel-registration-token (keep private)"
    exit 0
  fi
  sleep 3
done
echo "Tuwunel did not answer; check: journalctl -u tuwunel" >&2
exit 1
