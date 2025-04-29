#!/bin/sh

# exit if something fails
set -e

if [ "$(id -u)" != "0" ]; then
    echo $0 must be run as root
    exit 1
fi

ts=$(date +"%Y-%m-%d-%T")
backup=/tmp/systems-$ts

echo -n "Backing up existing files to $backup..."

mkdir -p $backup/apache2 $backup/colobus $backup/postfix $backup/supervisor

crontab -u root -l > $backup/crontab

# only back up files if they aren't a symlink

[ ! -h /etc/apache2/sites-available/news.php.net ] && \
    cp /etc/apache2/sites-available/news.php.net $backup/apache2/news.php.net.conf

[ ! -h /local/colobus/config ] && cp /local/colobus/config $backup/colobus/config

cp /etc/supervisor/conf.d/* $backup/supervisor/

[ ! -h /etc/aliases ] && \
    cp /etc/aliases $backup/postfix/aliases
[ ! -h /etc/postfix/main.cf ] && \
    cp /etc/aliases $backup/postfix/main.cf

echo "done."

if [ ! -f /local/systems/lists/colobus/config ]; then
    echo $0: new config not available, not loading it
    exit 1
fi

echo -n "Putting new configuration into place..."

crontab -u root - < /local/systems/cron-box-crontab

# apache2
rm -f /etc/apache2/sites-enabled/*.conf
ln -s -t /etc/apache2/sites-enabled /local/systems/lists/apache2/*.conf
service apache2 reload

# postfix
rm -f /etc/aliases /etc/postfix/main.cf
ln -s /local/systems/lists/postfix/aliases /etc/aliases
ln -s /local/systems/lists/postfix/main.cf /etc/postfix
newaliases
service postfix reload

# supervisor
rm -f /etc/supervisor/conf.d/*.conf
ln -s -t /etc/supervisor/conf.d /local/systems/lists/supervisor/*.conf
service supervisor restart

echo "done."
