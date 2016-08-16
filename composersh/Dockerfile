FROM composer/composer:php5
MAINTAINER Eric Fehr ricofehr@nextdeploy.io
LABEL description="NextDeploy composersh command"

# copy import script
COPY composer.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/composer.sh

# Upgrade system
RUN /bin/sed -i "s;jessie main;jessie main contrib non-free;" /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y --force-yes
RUN DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y --force-yes

# Install prerequis
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl git sudo libxrender-dev libfontconfig1-dev libxext-dev mysql-client php-pear

# Install libraries for php extensions
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libpng12-dev libbz2-dev libjpeg62-turbo-dev  libjpeg-dev libpq-dev libcurl4-openssl-dev libldap2-dev libicu-dev libxml2-dev libmcrypt-dev libxslt-dev libtidy-dev libfreetype6-dev

# Install php extensions
RUN DEBIAN_FRONTEND=noninteractive ln -fs /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/ \
&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
&& docker-php-ext-install gd mbstring pdo pdo_mysql bcmath \
&& docker-php-ext-install curl ldap mcrypt xmlrpc intl xsl tidy \
&& rm -r /var/lib/apt/lists/*

# APC 
RUN pear config-set php_ini /usr/local/etc/php/php.ini
RUN pecl config-set php_ini /usr/local/etc/php/php.ini
RUN pecl install apcu-4.0.11

RUN mkdir -p /composer/cache/repo
RUN mkdir -p /composer/cache/files

# launch composer with www-data user
RUN groupmod -g 1000 www-data
RUN usermod -u 1000 www-data
RUN chown -R www-data: /composer

USER www-data
VOLUME /app
WORKDIR /app

# launch composer.sh script
ENTRYPOINT ["composer.sh", "/app"]
