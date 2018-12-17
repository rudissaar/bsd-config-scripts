#!/usr/bin/env sh

# You need root permissions to run this script.
if [ "$(id -u)" != '0' ]; then
    echo '> You need to become root to run this script.'
    exit 1
fi

# Install packages.
pkg install -y vim-console

grep -Fq 'alias vi' /etc/csh.cshrc

if [ "${?}" != '0' ]; then
    echo >> /etc/csh.cshrc
    echo "alias vi vim" >> /etc/csh.cshrc
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

# Set size of tab.
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

# Copy .vimrc file to user's directory.
cp /etc/skel/.vimrc "${HOME}"

echo '> Finished.'

