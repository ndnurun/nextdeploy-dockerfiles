FROM node:5.12.0

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN groupadd -g 1000 nodeapp
RUN useradd -u 1000 -g 1000 -s /bin/bash nodeapp
RUN chown 1000:1000 /usr/src/app
USER nodeapp
