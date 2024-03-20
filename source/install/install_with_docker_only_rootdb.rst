==============================
With Docker, only RootDB image
==============================


Prerequisite
============

| RootDB image contains PHP-FPM, with SourceGuardian_ module and Supervisor_.
| So you need to have a working :

* MariaDB_ server.
* Memcached_ instance.
* nginx_ proxy to access PHP-FPM that is running inside the container and also to access RootDB frontend files.


Services configuration
======================

You should :doc:`check the manual installation page<./install_without_docker>` to configure all different services.

Memcached
---------

Memcached should be configured to listen on the server IP instead of the localhost IP.

.. code-block:: ini
   :linenos:
   :emphasize-lines: 5
   :caption: /etc/memcached.conf

   # Specify which IP address to listen on. The default is to listen on all IP addresses
   # This parameter is one of the only security measures that memcached has, so make sure
   # it's listening on a firewalled interface.
   #-l 127.0.0.1
   -l www.xxx.yyy.zzz


Nginx
-----

Frontend
~~~~~~~~

| For an example of nginx configuration for the fronted :doc:`please check the manual installation page<./install_without_docker>`.

.. caution::

   Log that the ``root`` directory have to be set to ``/var/www/frontend/``


API
~~~

.. code-block:: nginx
   :linenos:
   :emphasize-lines: 3,7,8,12,13,18,37
   :caption: /etc/nginx/sites-available/<api.hostname.tld>

    server {
        listen 443 ssl;
        server_name <api.hostname.tld>;
        root        /var/www/api/public/;
        index       index.php;

        ssl_certificate     /etc/letsencrypt/live/<hostname.tld>/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/<hostname.tld>/privkey.pem;
        include             /etc/letsencrypt/options-ssl-nginx.conf;
        ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

        access_log /var/log/nginx/<api.hostname.tld>.access.log;
        error_log /var/log/nginx/<api.hostname.tld>.error.log;

       location ~ \.php$ {
            try_files                       $uri =404;
            fastcgi_split_path_info         ^(.+\.php)(/.+)$;
            fastcgi_pass                    <api.hostname.tld>:9000;
            fastcgi_index                   index.php;
            include                         fastcgi_params;
            fastcgi_buffers                 16 16k;
            fastcgi_buffer_size             32k;
            fastcgi_param SCRIPT_FILENAME   $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO         $fastcgi_path_info;
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

MariadDB
--------

| You have to create the RootDB API user, for that :doc:`please check then manual installation page<./install_without_docker>`.

Before running the image
========================

| First, create a directory ``rootdb`` that will contains these directories :  ``www``, ``tls`` and then, from ``rootdb`` directory, download a set of default configuration files for the API & frontend.

.. list-table:: Sets of API & Frontend configuration file
   :widths: 80 20
   :header-rows: 1

   * - Notes
     - Configuration files
   * - | Pre-configured config files to use with a custom hostname and **with TLS**.
       | RootdB will be available at : `front.hostname.tld:443`_
       | Replace ``api_hostname_tld``, ``front_hostname_tld``, ``hostname_tld`` by the hostnames you want to use in the configuration files.
       | Think also to replace ``database_host_ip``, ``memcached_host_ip`` by the right IP to access these services.
       | You should create a ``tls`` directory, inside your ``www`` directory, where you can store you certificate & private key files
       | Then update, if needed, ``LARAVEL_WEBSOCKETS_SSL_LOCAL_CERT``, ``LARAVEL_WEBSOCKETS_SSL_LOCAL_PK`` in ``api_env`` file.
       | You can also update RootDB API user password and other variable, it's up to you.
     - | :download:`api_env <../_static/docker/only_rdb/api_env>`
       | :download:`app-config.js <../_static/docker/only_rdb/app-config.js>`


.. caution::

   | ``app-config.js`` have to be stored into ``rootdb/www`` directory as ``.app-config.js``

.. caution::

   | Since we are using a nginx proxy to access PHP-FPM *inside* RootDB container but API files are available *outside* the container we have to make sure that RootDB API code is available with the same path outside and inside the container.
   | This simply mean we have to create, on our host which run nginx, a symlink to access RootDB API files. Eg :

   .. code-block:: bash

      ln -s /path/to/your/rootdb/www /var/www


| When MariaDB, Memcached and Nginx are configured and you downloaded all configuration files, you should have this kind of tree structure for your ``rootdb`` directory :

.. code-block:: bash

   /path/to/rootdb
   ├── [drwxr-xr-x] tls
   │ ├── fullchain.pem
   │ └── privkey.pem
   ├── [drwxr-xr-x] www
   │ └── [-rw-r--r--]  .app-config.js
   └── [-rw-r--r--]  api_env

| And in you ``/var`` directory :

.. code-block:: bash

   /var/
   └── www -> /path/to/rootdb/www/



Run the image
=============


| You can start RootDB image this way. (think to replace ``api_hostname_tld`` and ``/path/to/rootdb/``)

.. code-block:: bash

    docker  run -it \
                --name rootdb \
                --network bridge \
                --env UID=1000 \
                --env GID=1000 \
                --add-host api_hostname_tld:127.0.0.1 \
                -h rootdb \
                -p 6001:6001 \
                -p 9000:9000 \
                -p 11212:11211 \
                -v /path/to/rootdb/api_env:/var/www/.api_env \
                -v /path/to/rootdb/www/:/var/www/ \
                -v /path/to/rootdb/tls/:/var/www/tls \
                atomicwebsas/rootdb:latest


You can then restart / stop the container like any other containers :

.. code-block:: bash

    docker container start rootdb
    docker container stop rootdb

.. _Certbot: https://certbot.eff.org/
.. _front.hostname.tld:443: https://front.hostname.tld:443
.. _MariaDB: https://mariadb.org/documentation/
.. _Memcached: https://www.memcached.org/
.. _nginx: https://nginx.org/en/docs/
.. _SourceGuardian: https://www.sourceguardian.com/loaders.html
.. _Supervisor: http://supervisord.org/
