# Drush Docker Container
FROM drush/drush:base
MAINTAINER Eric Fehr ricofehr@nextdeploy.io
LABEL description="NextDeploy drush command"

# Set the Drush version.
ENV DRUSH_VERSION 8.1.7

# Install Drush 8 with the phar file.
RUN curl -fsSL -o /usr/local/bin/drush "https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar" && \
  chmod +x /usr/local/bin/drush

# Test your install.
RUN drush core-status

# Upgrade system
RUN /bin/sed -i "s;jessie main;jessie main contrib non-free;" /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y --force-yes
RUN DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y --force-yes

# Install prerequis
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y postfix wget curl git sudo libxrender-dev libfontconfig1-dev libxext-dev mysql-client php-pear imagemagick

# Install libraries for php extensions
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libpng12-dev libbz2-dev libjpeg62-turbo-dev  libjpeg-dev libpq-dev libcurl4-openssl-dev libldap2-dev libicu-dev libxml2-dev libmcrypt-dev libxslt-dev libtidy-dev libfreetype6-dev

# Install php extensions
RUN DEBIAN_FRONTEND=noninteractive ln -fs /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/ \
&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
&& docker-php-ext-install gd mbstring pdo pdo_mysql \
&& docker-php-ext-install curl ldap mcrypt xmlrpc intl xsl tidy

# Install php imagick extension
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libmagickwand-dev --no-install-recommends \
&& rm -rf /var/lib/apt/lists/*
RUN pecl install imagick && docker-php-ext-enable imagick
 
# launch drush with www-data user
RUN usermod -u 1000 www-data
USER www-data
WORKDIR /app
