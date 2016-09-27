FROM debian:jessie
MAINTAINER Eric Fehr ricofehr@nextdeploy.io
LABEL description="NextDeploy import command"

# copy import script
COPY import.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/import.sh

# pub   4096R/AAB2461C 2014-02-25 [expires: 2016-02-25]
#       Key fingerprint = DFFA 3DCF 326E 302C 4787  673A 01C4 E7FA AAB2 461C
# uid                  MongoDB 2.6 Release Signing Key <packaging@mongodb.com>
#
# pub   4096R/EA312927 2015-10-09 [expires: 2017-10-08]
#       Key fingerprint = 42F3 E95A 2C4F 0827 9C49  60AD D68F A50F EA31 2927
# uid                  MongoDB 3.2 Release Signing Key <packaging@mongodb.com>
#
ENV GPG_KEYS \
	DFFA3DCF326E302C4787673A01C4E7FAAAB2461C \
	42F3E95A2C4F08279C4960ADD68FA50FEA312927
RUN for key in $GPG_KEYS; do \
		apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
done

# add mongo repository
RUN echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.2 main" >> /etc/apt/sources.list

# Upgrade system
RUN /bin/sed -i "s;jessie main;jessie main contrib non-free;" /etc/apt/sources.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y --force-yes
RUN DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y --force-yes

# Install prerequis
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl git sudo libxrender-dev libfontconfig1-dev libxext-dev mysql-client

# Install libraries for php extensions
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libpng12-dev libbz2-dev libjpeg62-turbo-dev  libjpeg-dev libpq-dev libcurl4-openssl-dev libldap2-dev libicu-dev libxml2-dev libmcrypt-dev libxslt-dev libtidy-dev libfreetype6-dev

# install ncftp
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y ncftp

# install mysql and mongo client
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-client mongodb-org-shell mongodb-org-tools

# launch drush with www-data user
RUN usermod -u 1000 www-data
USER www-data
VOLUME /app
WORKDIR /app

# launch import.sh script
ENTRYPOINT ["import.sh"]
