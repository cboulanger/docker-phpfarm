#
# PHP Farm Docker image
#

# we use Debian as the host OS
FROM philcryer/min-jessie:latest

LABEL author="Andreas Gohr <andi@splitbrain.org>, Eugene Sia <eugene@eugenesia.co.uk>, Christian Boulanger <info@bibliograph.org>"

ENV \
  # Packages needed for running various build scripts.
  SCRIPT_PKGS=" \
    debian-keyring \
    wget \
  " \
  # Packages only needed for PHP build.
  BUILD_PKGS=" \
    autoconf \
    build-essential \
    lemon \
    bison \
    pkg-config \
    re2c \
  " \
  # PHP runtime dependencies.
  RUNTIME_PKGS=" \
    # Needed for PHP and Git to connect with SSL sites.
    ca-certificates \
    git \
    curl \
    mysql-client \
    unzip \
    locales \
    # apt-get complains that this is an 'essential' package.
    debian-archive-keyring \
    imagemagick \
    libbz2-dev \
    libc-client2007e-dev \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg-dev \
    libkrb5-dev \
    libldap2-dev \
    libltdl-dev \
    libmcrypt-dev \
    libmhash-dev \
    libmysqlclient-dev \
    libpng-dev \
    libpq-dev \
    libsasl2-dev \
    libsqlite3-dev \
    libssl-dev \
    libwebp-dev \
    libxml2-dev \
    libxpm-dev \
    libxslt1-dev \
    libzip-dev \
    locales \
    # needed for bibliograph
    yaz libyaz4-dev bibutils \
    # php 7.4
    libonig-dev \
  " \
  # Packages needed to run Apache httpd.
  APACHE_PKGS="\
    apache2 \
    apache2-mpm-prefork \
    # Fcgid mod for Apache - not a build dependency library.
    libapache2-mod-fcgid \
  "
ENV LANG=en_US.UTF-8

RUN \
  echo ">>> Installing packages we need for runtime usage" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
  $RUNTIME_PKGS \
  $APACHE_PKGS && \
  # Clean up apt package lists
  rm -rf /var/lib/apt/lists/* && \
  # Reconfigure Apache
  rm -rf /var/www/* && \
  # Configure locales
  sed -i -e "s/^# $LANG/$LANG/" /etc/locale.gen && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  update-locale LANG=$LANG

# Import our Apache configs.
COPY var-www /var/www/
COPY apache /etc/apache2/

# Import our own modifications for the PhpFarm script.
COPY phpfarm /phpfarm_mod

# The PHP versions to compile.
ENV PHP_FARM_VERSIONS="7.0.33-pear 7.1.33-pear 7.2.25-pear 7.3.12-pear 7.4.0-pear" \
  \
  # Flags for C Compiler Loader: make php 5.3 work again.
  LDFLAGS="-lssl -lcrypto -lstdc++" \
  \
  # Add path to built PHP executables, for module building and for Apache
  PATH="/phpfarm/inst/bin/:$PATH"

RUN \
  echo ">>> Installing packages needed for build" && \
  apt-get update && \
  apt-get install -y --no-install-recommends $SCRIPT_PKGS $BUILD_PKGS && \
  echo ">>> Downloading and patching PHPFarm" && \
  wget -O /phpfarm.tar.gz https://github.com/fpoirotte/phpfarm/archive/v0.3.0.tar.gz && \
  mkdir /phpfarm && \
  tar -xf /phpfarm.tar.gz -C /phpfarm --strip 1 && \
  rm -rf /phpfarm/src/bzips /phpfarm/src/custom && \
  mv /phpfarm_mod/* /phpfarm/src/ && \
  sleep 5s && \
  rmdir /phpfarm_mod && \
  echo ">>> Building all PHP versions" && \
  cd /phpfarm/src && \
  ./docker.sh && \
  echo ">>> Cleaning up" && \
  apt-get purge -y $SCRIPT_PKGS $BUILD_PKGS && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# expose the ports
EXPOSE 8000 8070 8071 8072 8073

# run it
WORKDIR /var/www
COPY run.sh /run.sh
CMD ["/bin/bash", "/run.sh"]

