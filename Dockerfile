ARG ARCH=
ARG PHP_VERSION=8.4
ARG DOLIBARR_VERSION=22.0.3

FROM ${ARCH}php:${PHP_VERSION}-fpm-alpine
RUN apk --no-cache update && apk --no-cache upgrade

# PREPARE PHP
RUN mv $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
RUN apk --no-cache add zlib-dev libpng-dev libjpeg-turbo-dev freetype-dev krb5-dev icu-dev gettext-dev libzip-dev imap-dev libpq-dev openldap-dev
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) intl gd opcache gettext calendar zip mysqli pgsql ldap

# PREPARE NGINX
RUN apk --no-cache add nginx
RUN cat > /etc/nginx/http.d/default.conf <<EOF
fastcgi_send_timeout 180s;
fastcgi_read_timeout 180s;
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        index index.php;
        root /var/www/dolibarr/htdocs;

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
                fastcgi_param PATH_INFO       \$fastcgi_path_info;
                fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_script_name;
                fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                fastcgi_hide_header X-Frame-Options;
                fastcgi_intercept_errors on;
        }
}
EOF

# DOWNLOAD AND INSTALL DOLIBARR
ARG DOLIBARR_VERSION
RUN wget https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.tar.gz -O - | tar -xz && \
    mv dolibarr-${DOLIBARR_VERSION} /var/www/dolibarr && \
    chown -R www-data:www-data /var/www/dolibarr && chmod -R 755 /var/www/dolibarr
RUN echo "<?php \$force_install_noedit = 1;" > /var/www/dolibarr/htdocs/install/install.forced.php
RUN mkdir /var/www/dolibarr/documents

EXPOSE 80
ENTRYPOINT [ "sh", "-c", "chown www-data:www-data /var/www/dolibarr/documents /var/www/dolibarr/htdocs/custom /var/www/dolibarr/htdocs/conf && nginx && php-fpm" ]
