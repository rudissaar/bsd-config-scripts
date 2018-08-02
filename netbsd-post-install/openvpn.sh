#!/usr/bin/env sh

OPENVPN_DIR='/usr/pkg/etc/openvpn/'

if [ "$(id -u)" != '0' ]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

[ -z "${PKG_PATH}" ]
if [ "${?}" = '0' ]; then
    PKG_PATH="http://cdn.NetBSD.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/$(uname -r|cut -f '1 2' -d.|cut -f 1 -d_)/All"
    export PKG_PATH
fi

pkg_add -v \
    openvpn \
    easy-rsa

if [ "$(sysctl -nw net.inet.ip.forwarding)" = '0' ]; then
    sysctl -w net.inet.ip.forwarding=1
fi

grep -Fq 'net.inet.ip.forwarding=1' /etc/sysctl.conf

if [ "${?}" != '0' ]; then
    echo -e "\n# Enable IPv4 forwarding." >> /etc/sysctl.conf
    echo 'net.inet.ip.forwarding=1' >> /etc/sysctl.conf
fi

cp '/usr/pkg/share/examples/openvpn/config/server.conf' "${OPENVPN_DIR}"
TMP_FILE=$(mktemp)
egrep -v "^#|^;|^$" "${OPENVPN_DIR}server.conf" > "${TMP_FILE}"
mv "${TMP_FILE}" "${OPENVPN_DIR}server.conf"
