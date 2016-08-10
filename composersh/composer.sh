#!/bin/bash

DOCROOT="$1"
[[ -z "$DOCROOT" ]] && exit 1
[[ ! -f /usr/bin/php ]] && echo "No php binary found" && exit 0

[[ -z "$LANG" ]] && export LANG=en_US.UTF-8
[[ -z "$HOME" ]] && export HOME=/var/www

ISRESET="$3"
[[ -z "$ISRESET" ]] && ISRESET="false"

pushd $DOCROOT >/dev/null
(( $? != 0 )) && exit 1
find . -maxdepth 6 -name composer.json | grep -v "vendor" | while read GFILE; do
  pushd "${GFILE%/*}" >/dev/null
  if [[ -f composer.lock ]] || [[ "$PWD" =~ ^.*/html.*$ ]]; then
    [[ "$ISRESET" = "true" ]] && rm -rf vendor
    [[ -f composer.phar ]] && rm -f composer.phar
    curl -sS https://getcomposer.org/installer | php
    php composer.phar install -n --prefer-dist --no-dev
    # if composer fails, sometimes is caused by github rates, sleep and try again
    (( $? != 0 )) && sleep 20 && /usr/bin/php composer.phar install -n --prefer-dist --no-dev
    rm -f composer.phar
  fi
  popd >/dev/null
done
popd > /dev/null
