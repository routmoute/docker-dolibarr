ARG ARCH=
ARG PHP_VERSION=8.4
ARG DOLIBARR_VERSION=22.0.4

FROM ${ARCH}php:${PHP_VERSION}-fpm-alpine

# Install dependencies and PHP extensions
RUN apk --no-cache update && apk --no-cache upgrade && \
    apk --no-cache add build-base autoconf zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev krb5-dev icu-dev gettext-dev libzip-dev imap-dev libpq-dev openldap-dev nginx && \
    mv $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini && \
    pecl install imap && docker-php-ext-enable imap && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) intl gd opcache gettext calendar zip mysqli pgsql ldap && \
    apk del build-base autoconf zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev krb5-dev icu-dev gettext-dev libzip-dev imap-dev libpq-dev openldap-dev && \
    rm -rf /var/cache/apk/*

# Configure PHP
RUN echo "session.use_strict_mode = 1" >> $PHP_INI_DIR/php.ini && \
    echo "open_basedir = /var/www/dolibarr/htdocs:/var/www/dolibarr/documents:/tmp" >> $PHP_INI_DIR/php.ini && \
    echo "allow_url_fopen = 0" >> $PHP_INI_DIR/php.ini && \
    echo "disable_functions = show_source,passthru,shell_exec,system,proc_open,popen" >> $PHP_INI_DIR/php.ini && \
    echo "opcache.enable = 1" >> $PHP_INI_DIR/php.ini

# Configure Nginx
RUN sed -i 's/user nginx;/user www-data;/' /etc/nginx/nginx.conf
RUN cat > /etc/nginx/http.d/default.conf <<EOF
fastcgi_send_timeout 180s;
fastcgi_read_timeout 180s;
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/x-javascript;
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    index index.php;
    root /var/www/dolibarr/htdocs;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';";
    location ~ [^/]\.php(/|\$) {
        fastcgi_split_path_info ^(.+\.php)(.*)\$;
        if (!-f \$document_root\$fastcgi_script_name) {
            return 404;
        }
        root /var/www/dolibarr/htdocs;
        fastcgi_pass 127.0.0.1:9000;
        include fastcgi_params;
        fastcgi_index index.php;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_script_name;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_hide_header X-Frame-Options;
        fastcgi_intercept_errors on;
    }
}
EOF

# Download and install Dolibarr
ARG DOLIBARR_VERSION
RUN wget https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.tar.gz -O - | tar -xz && \
    mv dolibarr-${DOLIBARR_VERSION} /var/www/dolibarr && \
    mkdir /var/www/dolibarr/documents && \
    chown -R www-data:www-data /var/www/dolibarr && \
    chmod -R 500 /var/www/dolibarr && \
    chmod -R 700 /var/www/dolibarr/documents /var/www/dolibarr/htdocs/custom /var/www/dolibarr/htdocs/conf

# Preconfigure Dolibarr
RUN echo "<?php \$force_install_noedit = 1;" > /var/www/dolibarr/htdocs/install/install.forced.php

EXPOSE 80
ENTRYPOINT [ "sh", "-c", "nginx && php-fpm" ]
