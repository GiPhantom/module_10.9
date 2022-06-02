FROM alpine:3.11

#ADD https://php.hernandev.com/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub
ADD https://packages.whatwedo.ch/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

# make sure you can use HTTPS
RUN apk --update add ca-certificates
RUN echo "https://packages.whatwedo.ch/v3.11/php-7.4/x86_64/" >> /etc/apk/repositories

# https://github.com/codecasts/php-alpine/issues/21
RUN /usr/bin/python3.8 -m pip install --upgrade pip
RUN rm /usr/bin/php
RUN ln -s /usr/bin/php7 /usr/bin/php
# upgrade pip
RUN /usr/bin/python3.8 -m pip install --upgrade pip
RUN pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U

#install setuptools and testinfra
RUN pip3 install setuptools pytest-testinfra

# https://github.com/codecasts/php-alpine/issues/21
#RUN rm /usr/bin/php
#RUN ln -s /usr/bin/php7 /usr/bin/php

# Install packages
FROM nginx:1.16.0-alpine
RUN apk --no-cache add php php-fpm php-opcache php-openssl php-curl \
    supervisor curl

RUN apk update && apk add --no-cache wget
RUN apk add --no-cache libuv \
    && apk add --no-cache --update-cache  nodejs nodejs-npm \
    && echo "NodeJS Version:" "$(node -v)" \
    && echo "NPM Version:" "$(npm -v)"

RUN node --version
RUN apk add --update npm
# upgrade pip
#RUN /usr/bin/python3.8 -m pip install --upgrade pip 
#RUN pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U

#install setuptools and testinfra
#RUN pip3 install setuptools pytest-testinfra

# https://github.com/codecasts/php-alpine/issues/21
#RUN rm /usr/bin/php
#RUN ln -s /usr/bin/php7 /usr/bin/php

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# create test folder
#RUN mkdir -p /etc/nginx/test
#RUN rm /etc/nginx/test
#RUN mkdir -p /etc/nginx/test
#add test file
RUN mkdir /etc/nginx/test
RUN mkdir /etc/nginx/test_report
COPY test.py /etc/nginx/test
#COPY /etc/nginx/test/test_alpine.py /etc/nginx/test
# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
RUN pytest /etc/nginx/test/test.py
#RUN testinfra /etc/nginx/test/test_infra.py
