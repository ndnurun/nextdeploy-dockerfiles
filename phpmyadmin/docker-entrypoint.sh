#!/bin/bash
set -e

BLOWFISH="${RANDOM}${RANDOM}"
CONFIGFILE="/var/www/html/config.inc.php"

# set mysql settings
DB_HOST=${DB_HOST:-mysql}
DB_USER=${DB_USER:-root}
DB_PASSWORD=${DB_PASSWORD:-8to9or1}

# set blowfish secret
sed -i "s;%%BLOWFISH%%;${BLOWFISH};" $CONFIGFILE
sed -i "s;%%DB_HOST%%;${DB_HOST};" $CONFIGFILE
sed -i "s;%%DB_USER%%;${DB_USER};" $CONFIGFILE
sed -i "s;%%DB_PASSWORD%%;${DB_PASSWORD};" $CONFIGFILE

exec "apache2-foreground"
