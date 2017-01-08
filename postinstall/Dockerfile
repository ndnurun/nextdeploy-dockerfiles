FROM drush/drush
MAINTAINER Eric Fehr ricofehr@nextdeploy.io
LABEL description="Nextdeploy postinstall cmd"

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
&& docker-php-ext-install gd mbstring pdo pdo_mysql \
&& docker-php-ext-install curl ldap mcrypt xmlrpc intl xsl tidy bcmath \
&& rm -r /var/lib/apt/lists/*

# APC
RUN pear config-set php_ini /usr/local/etc/php/php.ini
RUN pecl config-set php_ini /usr/local/etc/php/php.ini
RUN pecl install apcu-4.0.11
RUN echo 'extension=apcu.so' > /usr/local/etc/php/conf.d/apcu.ini

# Mongo
RUN /usr/bin/yes '' | /usr/bin/pecl install --force mongo-1.5.8
RUN echo 'extension=mongo.so' > /usr/local/etc/php/conf.d/mongo.ini

# ensure drush can be executed by all
#RUN mv /root/composer /opt
#RUN ln -sf /opt/composer/vendor/drush/drush/drush.php /usr/local/bin/drush
#RUN chown -R www-data: /opt/composer

# install wp
RUN cd /usr/local/bin && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar wp

# Memory Limit
RUN echo "memory_limit=1024M" > /usr/local/etc/php/conf.d/memory-limit.ini
# Time Zone
RUN echo "date.timezone=${PHP_TIMEZONE:-UTC}" > /usr/local/etc/php/conf.d/date_timezone.ini

# launch drush with www-data user
RUN usermod -u 1000 www-data
USER www-data
VOLUME /app
WORKDIR /app

# launch postinstall.sh script
ENTRYPOINT ["/bin/bash", "scripts/postinstall.sh"]
