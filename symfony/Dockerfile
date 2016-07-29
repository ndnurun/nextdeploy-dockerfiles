FROM php:5.6-apache
MAINTAINER Eric Fehr ricofehr@nextdeploy.io
LABEL description="NextDeploy Symfony container"

COPY php.ini /usr/local/etc/php/

# enable some apache modules
RUN a2enmod rewrite alias autoindex deflate expires headers include mime

# apache vhost
COPY 000-default.conf /etc/apache2/sites-available/

# Enable non-free and contrib packages
RUN /bin/sed -i "s;jessie main;jessie main contrib non-free;" /etc/apt/sources.list

# Install some other php5 extensions
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y --force-yes
RUN DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y --force-yes

# Install prerequis
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y postfix wget curl git sudo libxrender-dev libfontconfig1-dev libxext-dev mysql-client php-pear

# Install libraries for php extensions
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libpng12-dev libbz2-dev libjpeg62-turbo-dev  libjpeg-dev libpq-dev libcurl4-openssl-dev libldap2-dev libicu-dev libxml2-dev libmcrypt-dev libxslt-dev libtidy-dev libfreetype6-dev

# Install php extensions
RUN DEBIAN_FRONTEND=noninteractive ln -fs /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/ \
&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
&& docker-php-ext-install gd mbstring pdo pdo_mysql \
&& docker-php-ext-install curl ldap mcrypt xmlrpc intl xsl tidy \
&& rm -r /var/lib/apt/lists/*

# Install wkhtmltopdf
RUN DEBIAN_FRONTEND=noninteractive wget http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz
RUN DEBIAN_FRONTEND=noninteractive tar xvf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz
RUN DEBIAN_FRONTEND=noninteractive mv wkhtmltox/bin/wkhtmltopdf /usr/bin/
RUN DEBIAN_FRONTEND=noninteractive rm -rf wkhtmltox
RUN DEBIAN_FRONTEND=noninteractive rm -f wkhtmltox-0.12.3_linux-generic-amd64.tar.xz

# Ensure php modules are enabled
#RUN rm -rf /usr/local/etc/php/conf.d
#RUN cp -rf /etc/php5/mods-available /usr/local/etc/php/conf.d

# Ensure that php can write sessions into the container
RUN chmod 777 /var/lib/php5

# Suppose current host user has uid 1000, it keep well permission on volume share
RUN groupmod -g 1000 www-data
RUN usermod -u 1000 www-data

# Shared folder
VOLUME /var/www/html
