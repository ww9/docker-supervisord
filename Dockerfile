# Usage:
# docker rm -f supervisordtest && docker build -t supervisordtest . && docker run --rm -p 8000:80 --init -it --name supervisordtest -v E:\\dev\\docker-rodrigo:/root/app supervisordtest
# Then open: http://127.0.0.1:8000/
# To inspect files while container is running: docker exec -it supervisordtest bash
# References:
# https://github.com/adhocore/docker-lemp
# https://github.com/wyveo/nginx-php-fpm

FROM ubuntu:20.04
SHELL ["/usr/bin/bash", "-c"]
EXPOSE 80 443 3306
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /root/app
VOLUME /root/app

########################################### language and locales ###########################################
ENV TZ=America/Cuiaba
ENV LC_ALL=pt_BR.UTF-8
ENV LANG=pt_BR.UTF-8
ENV LANGUAGE=pt_BR.UTF-8

RUN apt-get update -y \
	&& apt-get install -y \
	ca-certificates \
	software-properties-common \
	apt-transport-https \
	apt-utils \
	locales \
	tzdata

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
	&& echo $TZ > /etc/timezone \
	&& locale-gen pt_BR.UTF-8 \
	&& /usr/sbin/update-locale

########################################### supervisor and utilities ###########################################
RUN apt-get install -y supervisor git zip unzip vim curl wget netcat htop telnet whois lsb-release iputils-ping iputils-tracepath

########################################### php 8 ###########################################
RUN apt-add-repository -y ppa:ondrej/php \
	&& apt-get update -y \
	&& apt-get install -y \
	php8.0-apcu \
	php8.0-cli \
	php8.0-fpm \
	php8.0-dev \
	php8.0-common \
	php8.0-bcmath \
	php8.0-curl \
	php8.0-gd \
	php8.0-imagick \
	php8.0-intl \
	php8.0-mbstring \
	php8.0-mysql \
	php8.0-opcache \
	php8.0-readline \
	php8.0-redis \
	php8.0-xml \
	php8.0-xdebug \
	php8.0-zip \
	php-pear

RUN rm -rf /etc/php/8.0/fpm/php.ini \
	&& rm -rf /etc/php/8.0/fpm/pool.d/www.conf

########################################### php composer ###########################################
RUN curl --silent --show-error https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

########################################### nginx ###########################################
RUN apt-add-repository -y ppa:nginx/stable \
	&& apt-get update -y \
	&& apt-get install -y nginx

########################################### redis ###########################################
# # redis https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-redis-on-ubuntu-20-04
# RUN apt-get install -y redis-server

########################################### cleanup to make image smaller  ###########################################
# Clean cache so image is lighter
# RUN apt-get clean && rm -rf /var/lib/apt/lists/*

########################################### config files  ###########################################
# Config files go last so it's faster to tweak and rebuild
RUN rm -rf /etc/nginx/conf.d/default.conf
COPY docker/nginx.conf /root/nginx.conf
COPY docker/php.ini /root/php.ini
COPY docker/php_fpm.conf /root/php_fpm.conf
COPY docker/supervisor.conf /root/supervisor.conf

########################################### run  ###########################################
# -j/--pidfile FILENAME -- write a pid file for the daemon process to FILENAME
# -n/--nodaemon -- run in the foreground (same as 'nodaemon=true' in config file)
CMD ["supervisord", "-n", "-j", "/supervisord.pid", "-c", "/root/supervisor.conf"]