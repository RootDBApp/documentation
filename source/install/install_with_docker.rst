===========
With Docker
===========

| The easiest way to run RootDB is to use our officials Docker_ images, with compose_ plugin to start all services.



Download ready-to-use archives
==============================

| We provide different set of Docker ``env`` & ``compose`` configuration files in the table below.
| You will be able to quickly test locally or install in a production environnement with or without TLS access.
|
| Simply download one of the `.zip` files in the table below, extract it, and open a terminal in the extracted directory.

.. list-table:: All  set of Docker ``.env`` & ``compose`` files with default API and frontend configuration files.
   :widths: 10 60 20
   :header-rows: 1

   * - Services
     - Notes
     - Configuration files
   * - All-in-one
     - | Contains everything and works out-of-the box, **ideal to test in local**.
       | **TLDR** : Download the archive, extract, go into the extracted directory and run :

        .. code-block:: bash

            docker compose --env-file env up

       | RootdB will be available at : `localhost:8080`_
     - | :download:`rdb_mariadb_memcached.zip <https://github.com/RootDBApp/infra/raw/main/docker-compose/rdb_mariadb_memcached.zip>`
   * - All-in-one, custom hostname, with TLS
     - | Contains everything you need, with pre-configured config files to use with a custom hostname, **with TLS**.
       | RootdB will be available at a default : `front.hostname.tld:443`_ but,
       | you should replace ``api_hostname_tld``, ``front_hostname_tld``, ``hostname_tld`` by the hostnames you want to use in the configuration files.
       | You can use these commands to update all the files with your custom hostnames :

        .. code-block:: bash

            sed -i 's/api_hostname_tld/<YOUR-API.DOMAIN.TLD>/g' api_env app-config.js env
            sed -i 's/front_hostname_tld/<YOUR-FRONTEND.DOMAIN.TLD>/g' api_env app-config.js env
            sed -i 's/hostname_tld/<DOMAIN.TLD>/g' api_env app-config.js env

       | You should store you certificate & private key files inside the ``www/tls`` directory and think to put the right access grants :

        .. code-block:: bash

            chmod 644 <LOCAL_CERT>
            chmod 600 <LOCAL_PK>

       | Then update, if needed, ``LARAVEL_WEBSOCKETS_SSL_LOCAL_CERT``, ``LARAVEL_WEBSOCKETS_SSL_LOCAL_PK`` in ``api_env``, and ``NGINX_SSL_CERTS_DIR`` in Docker ``env`` file.
     - | :download:`rdb_mariadb_memcached_tls.zip <https://github.com/RootDBApp/infra/raw/main/docker-compose/rdb_mariadb_memcached_tls.zip>`

.. caution::

   | If the current user which will start services has a ``user id`` or ``group id`` different from ``1000``, you have to update docker ``env`` variables ``UID`` & ``GID`` with the right values.
   | To find-out your current ``user id`` & ``group id``, use the command ``id``

.. list-table:: docker ``env`` Variables explanation
   :widths: 20 80
   :header-rows: 1

   * - Note
     - Description
   * - ``DATA_DIR``
     - Relative or full path to the directory which (will) contains RootDB code. (/var/www directory inside the container)
   * - ``DB_DATA_DIR``
     -  Relative or full path to the directory which (will) contains MariaDB data.
   * - ``API_ENV_PATHNAME``
     -  Relative or full path to API configuration file. ( ``api_env`` )
   * - ``FRONTEND_APP_CONFIG_PATHNAME``
     -  Relative or full path to frontend configuration file. ( ``app-config.js`` )
   * - ``UID``
     - User ID ( default : 1000 )
   * - ``GID``
     - Group ID ( default : 1000 )


Before starting services
------------------------

For log, at this point you should have a directory named, for instance, ``rootdb``, and inside, these files and directories :

.. code-block:: bash

    .
    ├── [drwxr-xr-x] db
    ├── [drwxr-xr-x] www
    ├── [-rw-r--r--] api_env
    ├── [-rw-r--r--] app-config.js
    ├── [-rw-r--r--] docker-compose.yml
    └── [-rw-r--r--] env


Starting services
-----------------

.. code-block:: bash

    $ docker compose --env-file env -f docker-compose.yml up

| Once containers are up and running the application should take ~6s to initialize, for the first launch. (once images are downloaded)
| And you should see :

.. code-block:: default

    rootdb              | [16-Jun-2022 21:43:49] NOTICE: fpm is running, pid 1
    rootdb              | [16-Jun-2022 21:43:49] NOTICE: ready to handle connections

.. tip::

    It's now time to :doc:`setup the application<../setup/rootdb_setup>`.



.. _localhost:8080: http://localhost:8080
.. _front.hostname.tld:80: http://front.hostname.tld:80
.. _front.hostname.tld:443: https://front.hostname.tld:443
.. _Docker: https://docs.docker.com/engine/install/
.. _compose: https://docs.docker.com/compose/install/
