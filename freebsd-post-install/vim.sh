#!/usr/bin/env sh
# Script that installs and configures vim editor on current system.

# You need root permissions to run this script.
if [ "$(id -u)" != '0' ]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Install packages.
pkg install -y vim-console

if ! grep -Fq 'alias vi' /etc/csh.cshrc; then
    echo >> /etc/csh.cshrc
    echo "alias vi vim" >> /etc/csh.cshrc
fi

if [ ! -d /etc/skel ]; then
    mkdir -p /etc/skel
fi

if [ ! -f /etc/skel/.vimrc ]; then
    touch /etc/skel/.vimrc
fi

# Enable syntax.
if ! grep -Fq 'syntax on' /etc/skel/.vimrc; then
    echo 'syntax on' >> /etc/skel/.vimrc
fi

# Display line numbers.
if ! grep -Fq 'set number' /etc/skel/.vimrc; then
    echo 'set number' >> /etc/skel/.vimrc
fi

# Disable visual mode.
if ! grep -Fq 'set mouse-=a' /etc/skel/.vimrc; then
    echo 'set mouse-=a' >> /etc/skel/.vimrc
fi

# Set size of tab.
if ! grep -Fq 'set tabstop=4' /etc/skel/.vimrc; then
    echo 'set tabstop=4' >> /etc/skel/.vimrc
fi

# Use spaces instead of tabs.
if ! grep -Fq 'set expandtab' /etc/skel/.vimrc; then
    echo 'set expandtab' >> /etc/skel/.vimrc
fi

# Set size of indent.
if ! grep -Fq 'set shiftwidth=4' /etc/skel/.vimrc; then
    echo 'set shiftwidth=4' >> /etc/skel/.vimrc
fi

# Copy .vimrc file to user's directory.
cp /etc/skel/.vimrc "${HOME}"

# Let user know that script has finished its job.
echo '> Finished.'

