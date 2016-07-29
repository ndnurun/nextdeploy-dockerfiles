FROM iojs
MAINTAINER Eric Fehr ricofehr@nextdeploy.io
LABEL description="NextDeploy npmsh command"

# copy import script
COPY npm.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/npm.sh
RUN mkdir -p /var/www
RUN chown www-data /var/www

# launch drush with www-data user
RUN usermod -u 1000 www-data
USER www-data
VOLUME /app
WORKDIR /app

# launch npm.sh script
ENTRYPOINT ["npm.sh", "/app"]
