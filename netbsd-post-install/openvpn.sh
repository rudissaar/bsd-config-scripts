#!/usr/bin/env sh

OPENVPN_SERVER_DIR='/usr/pkg/etc/openvpn/'
EASY_RSA_BIN='/usr/pkg/bin/easyrsa'

OPENVPN_NETWORK='10.8.0.0'
OPENVPN_NETMASK='255.255.255.0'
OPENVPN_PROTOCOL='udp'
OPENVPN_PORT=1194

NAMESERVER_1='8.8.8.8'
NAMESERVER_2='8.8.4.4'

CRL_VERIFY=0
EDIT_VARS=0

if [ "$(id -u)" != '0' ]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

[ -z "${PKG_PATH}" ]
if [ "${?}" = '0' ]; then
    MIRROR='http://cdn.NetBSD.org/pub/pkgsrc/packages/NetBSD/'
    PKG_PATH="${MIRROR}$(uname -p)/$(uname -r|cut -f '1 2' -d.|cut -f 1 -d_)/All"
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
    ln -sf "${OPENVPN_SERVER_DIR}" /etc/openvpn
fi

# Create directory for Easy RSA if if doesn't exist.
if [ ! -d "${OPENVPN_SERVER_DIR}easy-rsa" ]; then
    mkdir -p "${OPENVPN_SERVER_DIR}easy-rsa"
fi

# Copy Easy RSA files to OpenVPN directory.
ln -sf "${EASY_RSA_BIN}" "${OPENVPN_SERVER_DIR}easy-rsa/easyrsa"

cp -r /usr/pkg/share/examples/easyrsa/* "${OPENVPN_SERVER_DIR}easy-rsa/"

# Edit vars with your default text editor, using vi as fallback.
if [ "${EDIT_VARS}" = '1' ]; then
    ${EDITOR:-vi} "${OPENVPN_SERVER_DIR}/easy-rsa/vars"
fi

# Generate keys.
cd "${OPENVPN_SERVER_DIR}/easy-rsa"
./easyrsa init-pki
touch "${OPENVPN_SERVER_DIR}/easy-rsa/pki/index.txt.attr"

# Generate new Diffie-Hellman key.
./easyrsa gen-dh
mv "${OPENVPN_SERVER_DIR}/easy-rsa/pki/dh.pem" "${OPENVPN_SERVER_DIR}"

# Generate CA key.
echo | ./easyrsa build-ca nopass
cp "${OPENVPN_SERVER_DIR}/easy-rsa/pki/ca.crt" "${OPENVPN_SERVER_DIR}"

# Generate Server key.
./easyrsa build-server-full server nopass
mv "${OPENVPN_SERVER_DIR}/easy-rsa/pki/issued/server.crt" "${OPENVPN_SERVER_DIR}"
mv "${OPENVPN_SERVER_DIR}/easy-rsa/pki/private/server.key" "${OPENVPN_SERVER_DIR}"

# Generate crl.pem file.
if [ "${CRL_VERIFY}" = '1' ]; then
    if [ ! -f "${OPENVPN_SERVER_DIR}/easy-rsa/pki/crl.pem" ]; then
        ./easyrsa gen-crl
    fi
fi

# Generate TLS Auth key.
openvpn --genkey --secret "${OPENVPN_SERVER_DIR}ta.key"

cd - 1> /dev/null

# Move example configuration file to OpenVPN's directory.
cp '/usr/pkg/share/examples/openvpn/config/server.conf' "${OPENVPN_SERVER_DIR}"
#TMP_FILE=$(mktemp)
#egrep -v "^#|^;|^$" "${OPENVPN_SERVER_DIR}server.conf" > "${TMP_FILE}"
#mv "${TMP_FILE}" "${OPENVPN_SERVER_DIR}server.conf"

# Change name of the Diffie-Hellman key file.
sed -i 's/^dh [^.]*\.pem$/dh dh.pem/g' "${OPENVPN_SERVER_DIR}/server.conf"

# Change Port if you specified new one.
if [ "${OPENVPN_PORT}" != '1194' ]; then
    sed -i '/^port 1194/s/1194/'${OPENVPN_PORT}'/' "${OPENVPN_SERVER_DIR}/server.conf"
fi

# Change Network if you specified new one.
if [ "${OPENVPN_NETWORK}" != '10.8.0.0' ]; then
    sed -i '/^server 10.8.0.0/s/10.8.0.0/'${OPENVPN_NETWORK}'/' "${OPENVPN_SERVER_DIR}/server.conf"
fi

# Change Netmask if you specified new one.
if [ "${OPENVPN_NETMASK}" != '255.255.255.0' ]; then
    sed -i \
       '/^server '${OPENVPN_NETWORK}' 255.255.255.0/s/ 255.255.255.0/ '${OPENVPN_NETMASK}'/' \
        "${OPENVPN_SERVER_DIR}/server.conf"
fi

# Uncomment redirect-gateway line.
sed -i '/;push "redirect-gateway def1 bypass-dhcp"/s/^;//g' "${OPENVPN_SERVER_DIR}/server.conf"

# Uncomment and set DNS servers.
sed -i \
    's/^;push "dhcp-option DNS .*/push "dhcp-option DNS '${NAMESERVER_1}'"/' \
    "${OPENVPN_SERVER_DIR}/server.conf"

# Enable CRL (Certificate Revocation List).
if [ "${CRL_VERIFY}" = '1' ]; then
    grep -Fq 'crl-verify' "${OPENVPN_SERVER_DIR}/server.conf"

    if [ "${?}" != '0' ]; then
        echo -e \
            "\n\n# Use certificate revocation list." \
            >> "${OPENVPN_SERVER_DIR}/server.conf"

        echo \
            "crl-verify ${OPENVPN_SERVER_DIR}/easy-rsa/pki/crl.pem" \
            >> "${OPENVPN_SERVER_DIR}/server.conf"
    fi
fi

# Enable LZO compression.
if [ "${LZO_COMPRESSION}" = '1' ]; then
    sed -i '/;comp-lzo/s/^;//g' "${OPENVPN_SERVER_DIR}/server.conf"
fi
