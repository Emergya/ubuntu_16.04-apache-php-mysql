FROM ubuntu:16.04

ENV BUILD_TIMESTAMP 201704051337
ENV LOCALE en_US.UTF-8
EXPOSE 80 443 22

ADD assets/etc/apt /assets/etc/apt

RUN /bin/bash -c 'ln -fs /assets/etc/apt/sources.list /etc/apt/sources.list' && /bin/bash -c 'ln -fs /assets/etc/apt/apt.conf.d/99recommends /etc/apt/apt.conf.d/99recommends'

RUN apt-get update && \
    # base depends
    DEBIAN_FRONTEND=noninteractive apt-get install -y locales net-tools iputils-ping iproute2 sysstat iotop tcpdump tcpick bwm-ng tree strace screen rsync inotify-tools socat wget curl \
    openssh-server openssh-client build-essential automake make autoconf libpcre3-dev software-properties-common supervisor sudo git vim emacs python-minimal fontconfig ssmtp mailutils \
    bash-completion less unzip \
    # stack services depends 
    apache2 apache2-utils mysql-client mysql-server 

    #clean apt
RUN rm -rf /var/lib/apt/lists/*

#Install php 7.2
RUN apt-get update &&  \
    apt install -y ca-certificates apt-transport-https && \
    wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add - && \
    echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list && \
    apt-get update && \
    apt install -y php7.2 && \
    apt install -y php7.2-cli php7.2-common php7.2-curl php7.2-mbstring php7.2-mysql php7.2-xml php7.2-dev libapache2-mod-php7.2 libapache2-mod-geoip geoip-database

RUN apt-get install -y php-xdebug php7.2-bcmath && \
    wget http://ftp.cz.debian.org/debian/pool/main/libj/libjpeg-turbo/libjpeg62-turbo_1.5.1-2_amd64.deb && \
    wget http://ftp.ee.debian.org/debian/pool/main/libw/libwebp/libwebp6_0.5.2-1_amd64.deb && \
    dpkg -i libjpeg62-turbo_1.5.1-2_amd64.deb libwebp6_0.5.2-1_amd64.deb && \
    apt-get install -y php7.2-gd


RUN locale-gen $LOCALE && update-locale LANG=$LOCALE

## Install Composer
RUN curl -k -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

# Setup mariadb
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql: /var/run/mysqld && \
    mv /etc/mysql/my.cnf /etc/mysql/my.cnf.dist && \
    mv /var/lib/mysql /var/lib/mysql.dist

# Setup Apache
RUN mkdir -p /var/run/apache2 && \
    chown -R www-data: /var/run/apache2 && \
    a2enmod actions alias authz_host deflate dir expires headers mime rewrite ssl php7.2 proxy proxy_http && \
    mv /etc/apache2/sites-enabled /etc/apache2/sites-enabled.dist

# Setup ssh
RUN mkdir -p /var/run/sshd

# since this image will not be built as frequently as before, 
# every individual asset inclusion is replaced by the general on-entrypoint-rsynced one
ADD assets /assets

VOLUME ["/var/log/apache2","/var/log/supervisor","/var/log/mysql","/var/lib/mysql"]
ENTRYPOINT ["/assets/bin/entrypoint"]
