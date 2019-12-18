#!/usr/bin/env sh
# Script that installs nginx and php stack on current system.

PHP_MAJOR_VERSION=7
PHP_MINOR_VERSION=3

ENABLE_SERVICES=1
USE_PRODUCTION_INI_FILE=1

# You need root permissions to run this script.
if [ "$(id -u)" != '0' ]; then
    echo '> You need to become root to run this script.'
    echo '> Aborting.'
    exit 1
fi

# Install packages.
pkg install -y \
    nginx \
    "php${PHP_MAJOR_VERSION}${PHP_MINOR_VERSION}" \
    "php${PHP_MAJOR_VERSION}${PHP_MINOR_VERSION}-extensions" \
    "php${PHP_MAJOR_VERSION}${PHP_MINOR_VERSION}-composer"

# Fix configuration.
sed -i -E '/^;listen.owner = */s/^;//g' /usr/local/etc/php-fpm.d/www.conf
sed -i -E '/^;listen.group = */s/^;//g' /usr/local/etc/php-fpm.d/www.conf
sed -i -E '/^;listen.mode = */s/^;//g' /usr/local/etc/php-fpm.d/www.conf

if [ ${USE_PRODUCTION_INI_FILE} -eq 1 ]; then
    cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
else
    cp /usr/local/etc/php.ini-development /usr/local/etc/php.ini
fi

# Configuring services.
if [ "${ENABLE_SERVICES}" = '1' ]; then
    sysrc nginx_enable=YES
    sysrc php_fpm_enable=YES

    service nginx restart
    service php-fpm restart
fi

# Let user know that script has finished its job.
echo '> Finished.'

