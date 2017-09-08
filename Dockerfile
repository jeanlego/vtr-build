# ------------------------------------------------------------------------------
# Based on a work at https://github.com/docker/docker.
# 
# aarch64 version adapted from original kdelfour/cloud9-docker image
#  - https://hub.docker.com/r/kdelfour/cloud9-docker/
# ------------------------------------------------------------------------------
# Pull base image.
FROM wgbartley/aarch64-supervisor-docker
MAINTAINER Garrett Bartley <wgbartley@gmail.com>

# ------------------------------------------------------------------------------
# Install base
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y clang time supervisor build-essential  openssh-server g++ zip clang curl libssl-dev apache2-utils git libxml2-dev sshfs libx11-dev libxft-dev fontconfig libcairo2-dev gcc automake git cmake flex bison ctags gdb perl valgrind 


# ------------------------------------------------------------------------------
# Install Node.js
#RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs
RUN ln -s /usr/bin/nodejs /usr/bin/node
    
# ------------------------------------------------------------------------------
# Install Cloud9
RUN git clone https://github.com/c9/core.git /cloud9
WORKDIR /cloud9
ADD addendum/c9/core/scripts/install-sdk.sh /cloud9/scripts/install-sdk.sh
ADD addendum/c9/install/install.sh /cloud9/scripts/install.sh
RUN scripts/install-sdk.sh

# Tweak standlone.js conf
RUN sed -i -e 's_127.0.0.1_0.0.0.0_g' /cloud9/configs/standalone.js 

# Add supervisord conf
ADD conf/cloud9.conf /etc/supervisor/conf.d/

# ------------------------------------------------------------------------------
# Add volumes
RUN mkdir /workspace
VOLUME /workspace


# ------------------------------------------------------------------------------
# set clang as default compiler because it is more verbose and has a static analyser
RUN export CC=clang
RUN export CXX=clang++

# ------------------------------------------------------------------------------
# Install missing Perl modules
RUN echo y | cpan
RUN cpan -fi List::MoreUtils

# ------------------------------------------------------------------------------
# fix ssh folder
RUN mkdir -p /var/run/sshd
RUN chmod -Rf 0755 /var/run/sshd

# ------------------------------------------------------------------------------
# make ssh passwordless since it is localhost only
RUN mkdir -p ~/.ssh
RUN ssh-keygen -t rsa -P "" -f ~/.ssh/authorized_keys
RUN chmod 600 ~/.ssh/authorized_keys

# ------------------------------------------------------------------------------
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ------------------------------------------------------------------------------
# Expose ports.
EXPOSE 22
EXPOSE 80
EXPOSE 3000

# ------------------------------------------------------------------------------
# Start supervisor, define default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]