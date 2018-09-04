#!/usr/bin/env sh

# You need root permissions to run this script.
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
pkg_add -v vim

# Replace vi command with vim.
grep -Fq 'alias vi=' /etc/profile

if [ "${?}" != '0' ]; then
    echo >> /etc/profile
    echo "alias vi='vim'" >> /etc/profile
fi

if [ ! -f /etc/skel/.vimrc ]; then
    touch /etc/skel/.vimrc
fi

# Enable syntax.
grep -Fq 'syntax on' /etc/skel/.vimrc

if [ "${?}" != '0' ]; then
    echo 'syntax on' >> /etc/skel/.vimrc
fi

# Display line numbers.
grep -Fq 'set number' /etc/skel/.vimrc

if [ "${?}" != '0' ]; then
    echo 'set number' >> /etc/skel/.vimrc
fi

# Disable visual mode.
grep -Fq 'set mouse-=a' /etc/skel/.vimrc

if [ "${?}" != '0' ]; then
    echo 'set mouse-=a' >> /etc/skel/.vimrc
fi

# Sset size of tab.
grep -Fq 'set tabstop=4' /etc/skel/.vimrc

if [ "${?}" != '0' ]; then
    echo 'set tabstop=4' >> /etc/skel/.vimrc
fi

# Use spaces instead of tabs.
grep -Fq 'set expandtab' /etc/skel/.vimrc

if [ "${?}" != '0' ]; then
    echo 'set expandtab' >> /etc/skel/.vimrc
fi

# Set size of indent.
grep -Fq 'set shiftwidth=4' /etc/skel/.vimrc

if [ "${?}" != '0' ]; then
    echo 'set shiftwidth=4' >> /etc/skel/.vimrc
fi

echo '> Finished.'

