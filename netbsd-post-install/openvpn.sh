#!/usr/bin/env sh

OPENVPN_DIR='/usr/pkg/etc/openvpn/'
EASY_RSA_BIN='/usr/pkg/bin/easyrsa'

if [ "$(id -u)" != '0' ]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

[ -z "${PKG_PATH}" ]
if [ "${?}" = '0' ]; then
    PKG_PATH="http://cdn.NetBSD.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/$(uname -r|cut -f '1 2' -d.|cut -f 1 -d_)/All"
    export PKG_PATH
fi

# Install packages.
pkg_add -v \
    easy-rsa \
    openssl \
    openvpn

if [ "$(sysctl -nw net.inet.ip.forwarding)" = '0' ]; then
    sysctl -w net.inet.ip.forwarding=1
fi

grep -Fq 'net.inet.ip.forwarding=1' /etc/sysctl.conf

if [ "${?}" != '0' ]; then
    echo -e "\n# Enable IPv4 forwarding." >> /etc/sysctl.conf
    echo 'net.inet.ip.forwarding=1' >> /etc/sysctl.conf
fi

# Create symbolic link to be more similar to Linux structure.
if [ ! -L '/etc/openvpn' ] && [ ! -d '/etc/openvpn' ] ; then
    ln -sf "${OPENVPN_DIR}" /etc/openvpn
fi

# Create directory for Easy RSA if if doesn't exist.
if [ ! -d "${OPENVPN_DIR}easy-rsa" ]; then
    mkdir -p "${OPENVPN_DIR}easy-rsa"
fi

# Copy Easy RSA files to OpenVPN directory.
ln -sf "${EASY_RSA_BIN}" "${OPENVPN_DIR}easy-rsa/easyrsa"

cp -r /usr/pkg/share/examples/easyrsa/* "${OPENVPN_DIR}easy-rsa/"

# Move example configuration file to OpenVPN's directory.
cp '/usr/pkg/share/examples/openvpn/config/server.conf' "${OPENVPN_DIR}"
TMP_FILE=$(mktemp)
egrep -v "^#|^;|^$" "${OPENVPN_DIR}server.conf" > "${TMP_FILE}"
mv "${TMP_FILE}" "${OPENVPN_DIR}server.conf"

# Generate TLS Auth key.
openvpn --genkey --secret "${OPENVPN_DIR}ta.key"
