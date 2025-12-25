# Docker Dolibarr

A simple and light container with fully fonctional [Dolibarr](https://github.com/Dolibarr/dolibarr) powered by nginx and php-fpm

## Examples

### Docker run

```sh
docker run -p 80:80 \
    -v /yourLocalDolibarrFolder/dolibarr_documents:/var/www/dolibarr/documents \
    -v /yourLocalDolibarrFolder/dolibarr_custom:/var/www/dolibarr/htdocs/custom \
    -v /yourLocalDolibarrFolder/dolibarr_conf:/var/www/dolibarr/htdocs/conf \
    routmoute/dolibarr
```

### Docker-compose

```yaml
services:
  dolibarr:
    image: routmoute/dolibarr
    volumes:
      - ./dolibarr_documents:/var/www/dolibarr/documents
      - ./dolibarr_custom:/var/www/dolibarr/htdocs/custom
      - ./dolibarr_conf:/var/www/dolibarr/htdocs/conf
    ports:
      - 80:80
```

### Docker-compose with mariadb

With this docker compose, the database server is `database` on port `3306`.

```yaml
services:
  database:
    image: mariadb
    volumes:
      - ./dolibarr_database:/var/lib/mysql
    environment:
      MARIADB_DATABASE: dolibarr
      MARIADB_USER: dolibarr
      MARIADB_PASSWORD: mysqlPassword
      MARIADB_RANDOM_ROOT_PASSWORD: 1
      MARIADB_AUTO_UPGRADE: 1
  dolibarr:
    image: routmoute/dolibarr
    depends_on:
      - database
    volumes:
      - ./dolibarr_documents:/var/www/dolibarr/documents
      - ./dolibarr_custom:/var/www/dolibarr/htdocs/custom
      - ./dolibarr_conf:/var/www/dolibarr/htdocs/conf
    ports:
      - 80:80
```
