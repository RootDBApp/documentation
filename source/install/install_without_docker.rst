==============
Without Docker
==============

If you prefer to install RootDB without Docker_ you can install and configure all requirements directly on your
server and then use a bash script to bootstrap the application.

Requirements
============

RootDB's requirements are :

* PHP_  ``>= 8.2`` with these modules :

    * php-bcmath_
    * php-dom_
    * php-iconv_
    * php-gd_
    * php-mbstring_
    * php-memcached_
    * php-pcntl_
    * php-pdo_
    * php-mysql_
    * php-pgsql_
    * php-pdo_
    * php-zip_
* nginx_
* Memcached_
* MariaDB_
* Supervisor_, to manage API services.
* semver_, a tiny tool to handle versioning.


Ubuntu Server 22.04
-------------------

Install all dependencies with these commands, as ``root`` user :

.. code-block:: bash

    wget -O /usr/local/bin/semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver \
         && chmod +x /usr/local/bin/semver \
         && apt install -y software-properties-common \
         && add-apt-repository -y ppa:ondrej/php \
         && apt update \
         && apt install -y memcached mariadb-server php8.2 php8.2-gd php8.2-bcmath php8.2-dom php8.2-fpm php8.2-gd php8.2-iconv php8.2-mbstring php8.2-memcached php8.2-curl php8.2-mysql php8.2-pgsql php8.2-zip nginx postgresql-client-common supervisor


Debian 12
---------

Install all dependencies with these commands, as ``root`` user :

.. code-block:: bash

    wget -O /usr/local/bin/semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver \
        && chmod +x /usr/local/bin/semver \
        && apt install -y ca-certificates apt-transport-https software-properties-common wget curl lsb-release \
        && curl -sSL https://packages.sury.org/php/README.txt | sudo bash -x \
        && apt install -y memcached mariadb-server php8.2 php8.2-gd php8.2-bcmath php8.2-dom php8.2-fpm php8.2-iconv php8.2-mbstring php8.2-memcached php8.2-curl php8.2-mysql php8.2-pgsql php8.2-zip nginx postgresql-client-common supervisor

Services configuration
======================

MariaDB
-------

Here you should simply have an up and running MariaDB instance, with a a root user correctly configured.

Setup RootDB database and API user :

.. code-block:: sql

   CREATE DATABASE `rootdb-api`;

   -- If RootDB is installed on the same server that hosts the database
   GRANT USAGE ON `rootdb-api`.* TO 'rootdb_api_user'@'localhost' IDENTIFIED BY '<a_password>';
   GRANT SELECT, INSERT, CREATE, UPDATE, DELETE, DROP, INDEX, ALTER, SHOW VIEW, LOCK TABLES ON `rootdb-api`.* TO `rootdb_api_user`@`localhost`;

   -- If RootDB _is not_ installed on the same server that hosts the database. (change <rootdb_ip> by the server's IP where RootDB code is installed)
   GRANT USAGE ON `rootdb-api`.* TO 'rootdb_api_user'@'<rootdb_ip>' IDENTIFIED BY '<a_password>';
   GRANT  SELECT, INSERT, CREATE, UPDATE, DELETE, DROP, INDEX, ALTER, SHOW VIEW, LOCK TABLES ON `rootdb-api`.* TO `rootdb_api_user`@`<rootdb_ip>`;


Nginx
-----

Frontend
~~~~~~~~

Below an example for the frontend, using TLS with Certbot_ :

.. code-block:: nginx
   :linenos:
   :emphasize-lines: 3,4,7,8,9,10,18,19,48
   :caption: /etc/nginx/sites-available/<frontend.hostname.tld> ( download :download:`rootdb-frontend.hostname.tld <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/nginx/rootdb-frontend.hostname.tld>` )

    server {
        listen 443 ssl;
        server_name <frontend.hostname.tld>;
        root        /path/to/frontend/;
        index       index.html;

        ssl_certificate     /etc/letsencrypt/live/<hostname.tld>/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/<hostname.tld>/privkey.pem;
        # Remove this line below if you are not using Certbot
        ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
        ssl_session_cache shared:le_nginx_SSL:10m;
        ssl_session_timeout 1440m;
        ssl_session_tickets off;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers off;
        ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA";

        access_log /var/log/nginx/<frontend.hostname.tld>.access.log;
        error_log  /var/log/nginx/<frontend.hostname.tld>.error.log;

        large_client_header_buffers 4 32k;

        location ~ ^.*fonts\/(.*)$ {
            add_header          Access-Control-Allow-Origin *;
            proxy_pass          http://<api.hostname.tld>/api/theme/fonts/$1;
            proxy_http_version  1.1;
            proxy_set_header    X-Real-IP           $remote_addr;
            proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
            proxy_set_header    X-Forwarded-Proto   $scheme;
            proxy_set_header    X-NginX-Proxy       true;
            proxy_set_header    Upgrade             $http_upgrade;
            proxy_set_header    Connection          "upgrade";
        }

        location / {
                try_files $uri @index;
        }

        location @index {
            add_header Cache-Control "no-store, no-cache, must-revalidate";
            expires 0;
            try_files /index.html =404;
        }
    }

    server {
        listen 80;
        server_name <frontend.hostname.tld>;
        return 301 https://$host$request_uri;
    }

API
~~~

Below an example for the API, using TLS with Certbot_ :

.. code-block:: nginx
   :linenos:
   :emphasize-lines: 3,4,7,8,9,10,18,19,44
   :caption: /etc/nginx/sites-available/<api.hostname.tld> ( download :download:`rootdb-api.hostname.tld <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/nginx/rootdb-api.hostname.tld>` )

    server {
        listen 443 ssl;
        server_name <api.hostname.tld>;
        root        /path/to/api/public/;
        index       index.php;

        ssl_certificate     /etc/letsencrypt/live/<hostname.tld>/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/<hostname.tld>/privkey.pem;
        # Remove this line below if you are not using Certbot
        ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;
        ssl_session_cache shared:le_nginx_SSL:10m;
        ssl_session_timeout 1440m;
        ssl_session_tickets off;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers off;
        ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA";

        access_log /var/log/nginx/<api.hostname.tld>.access.log;
        error_log /var/log/nginx/<api.hostname.tld>.error.log;

        location ~ \.php$ {
            try_files                       $uri =404;
            fastcgi_split_path_info         ^(.+\.php)(/.+)$;
            fastcgi_pass                    unix:/var/run/php/php8.2-fpm.sock;
            fastcgi_index                   index.php;
            include                         fastcgi_params;
            fastcgi_buffers                 16 16k;
            fastcgi_buffer_size             32k;
            fastcgi_param SCRIPT_FILENAME   $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO         $fastcgi_path_info;
            fastcgi_param DOCUMENT_ROOT     $realpath_root;
            internal;
        }

        location / {
            try_files $uri $uri/ /index.php?$query_string;
            gzip_static on;
        }
    }

    server {
        listen 80;
        server_name <api.hostname.tld>;
        return 301 https://$host$request_uri;
    }


Check your configuration and reload nginx :

.. code-block:: bash

   nginx -t
   systemctl restart nginx


PHP-FPM
-------

You should probably raise the allowed memory for a PHP-FPM process in the ``php.ini`` file and also the size for a POST and uploaded file.

.. code-block:: ini
   :caption: /etc/php/8.2/fpm/php.ini

   memory_limit = 4000M
   upload_max_filesize = 500M
   post_max_size = 400M

SourceGuardian extension
~~~~~~~~~~~~~~~~~~~~~~~~

| To decipher encoded API code, you have to download the SourceGuardian PHP extension.
| You'll find it here_.

Once you have downloaded a ``.tar.gz`` archive on your server :

.. code-block:: bash

   tar xvf loaders.linux-x86_64.tar.gz

The file ``ixed.8.2.lin``, extracted from the archive above have to be copied into the PHP module directory, eg: ``/usr/lib/php/20210902/`` on Debian 11 based distro or ``/usr/lib/php/20220829/`` on Debian 12 distro.

Add this extension to the enf of ``php.ini`` file .

.. code-block:: ini
   :caption: /etc/php/8.2/fpm/php.ini

   # At the end of the file :
   extension=ixed.8.2.lin

.. code-block:: ini
   :caption: /etc/php/8.2/cli/php.ini

   # At the end of the file :
   extension=ixed.8.2.lin

Finally, check your PHP-FPM configuration and restart the process :

.. code-block:: bash

   php-fpm8.2 -t
   systemctl restart php8.2-fpm



Supervisor
----------

Supervisor handle the websocket server and cron jobs. Here are the configuration files :

.. code-block:: ini
   :linenos:
   :emphasize-lines: 3,8,11
   :caption: /etc/supervisor/conf.d/rootdb-websocket_server.conf ( download :download:`rootdb-api.hostname.tld <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/supervisor/rootdb-websocket_server.conf>` )

   [program:rootdb-websocket_server]
   process_name=%(program_name)s_%(process_num)02d
   command=php /path/to/api/artisan websockets:serve
   autostart=true
   autorestart=true
   stopasgroup=true
   killasgroup=true
   user=<www-data or httpd>
   numprocs=1
   redirect_stderr=true
   stdout_logfile=/path/to/api/storage/logs/websocket.log
   stopwaitsecs=3600

.. code-block:: ini
   :linenos:
   :emphasize-lines: 3,8,11
   :caption: /etc/supervisor/conf.d/rootdb-cron_scheduler.conf ( download :download:`rootdb-api.hostname.tld <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/supervisor/rootdb-cron_scheduler.conf>` )

   [program:rootdb-cron_scheduler]
   process_name=%(program_name)s_%(process_num)02d
   command=php /path/to/api/artisan schedule:run -q && exec /usr/bin/sleep 60
   autostart=true
   autorestart=true
   stopasgroup=true
   killasgroup=true
   user=<www-data or httpd>
   numprocs=1
   redirect_stderr=true

Firewall
--------

By default, you have to open these ports : ``80,443,6001``.


Logs
----

You should consider to logrotate_ theses logs files :

.. code-block:: default

   /path/to/api/storage/logs/laravel.log
   /path/to/api/storage/logs/websocket.log


API & frontend code
===================

Before **installing** RootDB code, make sure MariaDB is up and running.

Code organization
-----------------

For log, once installed, the code tree will looks like this :

.. code-block:: default

   ├── api -> /home/rootdb/www/archives/1.0.4/api
   ├── archives
   │  ├── 1.0.3
   │  │   ├── api
   │  │   └── frontend
   │  └── 1.0.4
   │      ├── api
   │      └── frontend
   │
   ├── frontend -> /home/rootdb/www/archives/1.0.4/frontend
   ├── .api_db_initialized
   ├── .api_env  <------------- contains all env variables for API.
   ├── .api_initialized
   ├── .app-config.js  <------- contains all env variables for frontend.
   ├── .front_initialized
   ├── .rdb_initialized
   └── .rdb_upgraded_to




How-to get the code
-------------------
A bash script is available here : :download:`install.sh <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/bash/install.sh>`  - which will simplify the code installation. It will :

1. Check if software requirements and mandatory php modules are available on your system.
2. `Download latest RootDB archive`_.
3. Extract the archive, organize .env files and boostrap RootDB :

   1) setup ``.api_env`` and ``.app-config.js``
   2) initialize the database
4. Upgrade automatically to a new version of RootDB.
5. Or rollback to a previous version.

You can run ``install.sh -h`` to see a list of available options.

How-to run install.sh
~~~~~~~~~~~~~~~~~~~~~

| First, you have to download a default :download:`env <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/bash/env>` file which will be used to configure the API and frontend env files.
| Edit this file, there are comments inside to help you.
| Then run the install script this way : ``install.sh -e ./env``


.. list-table:: Files to download for standalone installation
   :widths: 30 30 40
   :header-rows: 1

   * - File
     - Description
     - MD5 checksum
   * - :download:`install.sh <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/bash/install.sh>`
     - installer bash script
     - 1129f18b0b253f936cce6436defb123a
   * - :download:`env <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/bash/env>`
     - ENV file
     - 1b65b0d62ca5a433c3f6d862dbd78dee
   * - :download:`rootdb-api.hostname.tld <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/nginx/rootdb-api.hostname.tld>`
     - API Nginx proxy
     - d36838cc51defd3e686c7a8f29c3df15
   * - :download:`rootdb-frontend.hostname.tld <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/nginx/rootdb-frontend.hostname.tld>`
     - Frontend Nginx proxy
     - 2bf226b2284a7db4633466648231fef9
   * - :download:`rootdb-cron_scheduler.conf <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/supervisor/rootdb-cron_scheduler.conf>`
     - Supervisor configuration for cron jobs
     - 298fe65469546f38dde665ff7e84af4e
   * - :download:`rootdb-websocket_server.conf <https://raw.githubusercontent.com/atomicweb-sas/rootdb/main/supervisor/rootdb-websocket_server.conf>`
     - Supervisor configuration for websocket server
     - 478eee5f1d4b531c1ead616241347765


.. _Certbot: https://certbot.eff.org/
.. _docker-compose.yml: https://documentation.rootdb.fr/docker-compose.yml
.. _Download latest RootDB archive: https://www.rootdb.fr/downloads
.. _env: https://documentation.rootdb.fr/.env
.. _here: https://www.sourceguardian.com/loaders.html
.. _localhost:8080: http://localhost:8080
.. _logrotate: https://linux.die.net/man/8/logrotate
.. _Docker: https://docs.docker.com/engine/install/
.. _docker-compose: https://docs.docker.com/compose/install/
.. _PHP: https://www.php.net/manual/en/
.. _php-bcmath: https://www.php.net/manual/fr/ref.bc.php
.. _php-dom: https://www.php.net/manual/en/book.dom.php
.. _php-iconv: https://www.php.net/manual/fr/function.iconv.php
.. _php-gd: https://www.php.net/manual/fr/book.image.php
.. _php-mbstring: https://www.php.net/manual/en/book.mbstring.php
.. _php-memcached: https://github.com/php-memcached-dev/php-memcached
.. _php-pdo: https://www.php.net/manual/fr/book.pdo.php
.. _php-mysql: https://www.php.net/manual/fr/ref.pdo-mysql.php
.. _php-pgsql: https://www.php.net/manual/fr/ref.pdo-pgsql.php
.. _php-pcntl: https://www.php.net/manual/fr/book.pcntl.php
.. _php-zip: https://www.php.net/manual/fr/book.zip.php
.. _nginx: https://nginx.org/en/docs/
.. _Memcached: https://www.memcached.org/
.. _MariaDB: https://mariadb.org/documentation/
.. _Supervisor: http://supervisord.org/
.. _semver: https://github.com/fsaintjacques/semver-tool
