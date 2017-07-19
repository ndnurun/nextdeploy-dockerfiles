FROM ruby:2.4
MAINTAINER Eric Fehr ricofehr@nextdeploy.io
LABEL description="NextDeploy cli command"

# prerequisites packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y net-tools sudo
RUN echo "app ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers

# clean apt
RUN rm -rf /var/lib/apt/lists/*

# avoid ssh knowhost alerts
RUN echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN echo "UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config

# launch ndeploy with app user
RUN groupadd -g 1000 app
RUN useradd -u 1000 -d /home/app -m -g 1000 app

# create a default config file
WORKDIR /home/app
RUN touch .nextdeploy.conf
RUN echo 'email: usera@os.nextdeploy' > .nextdeploy.conf
RUN echo 'password: word123123' >> .nextdeploy.conf
RUN echo 'endpoint: api.nextdeploy.local' >> .nextdeploy.conf
RUN chown app: .nextdeploy.conf

USER app

# install the cli cmd
WORKDIR /tmp
RUN git clone https://github.com/ricofehr/nextdeploy-cli
WORKDIR /tmp/nextdeploy-cli
RUN bundle install
RUN sudo cp nextdeploy.rb /usr/local/bin/ndeploy
WORKDIR /tmp
RUN rm -rf nextdeploy-cli

VOLUME /app
WORKDIR /app

# launch ndeploy cli
ENTRYPOINT ["ndeploy"]
