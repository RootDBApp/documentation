===========
With Docker
===========

| The easiest way to run RootDB is to use our officials Docker_ images, with compose_ plugin to start all services.



Download ready-to-use archives
==============================

| We provide different set of Docker ``env`` & ``compose`` configuration files in the table below.
| You will be able to quickly test locally.
|
| Simply download one of the `.zip` files in the table below, extract it, and open a terminal in the extracted directory.

.. list-table:: All  set of Docker ``.env`` & ``compose`` files with default API and frontend configuration files.
   :widths: 10 60 20
   :header-rows: 1

   * - Services
     - Notes
     - Configuration files
   * - All-in-one (`docker-compose`)
     - | Contains everything and works out-of-the box, **ideal to test in local**.
       | **TLDR** : Download the archive, extract, go into the extracted directory and run :

        .. code-block:: bash

            docker compose --env-file env up

       | RootdB will be available at : `localhost:8091`_
     - | :download:`rdb_mariadb_memcached.zip <https://github.com/RootDBApp/infra/raw/main/docker-compose/rdb_mariadb_memcached.zip>`
   * - All-in-one (`podman-kube`)
     - | Thanks to ullgren_, you can also use a podman-kube_ manifest that contains everything and works out-of-the box, **ideal to test in local**.
       | **TLDR** : Download the `podman-kube.yaml` file, and in the directory containing the file :

        .. code-block:: bash

            # start
            podman play kube --start  podman-kube.yaml

            # stop
            podman play kube --down  podman-kube.yaml

       | RootdB will be available at : `localhost:8091`_
     - | :download:`podman-kube.yaml <https://raw.githubusercontent.com/RootDBApp/infra/main/podman-kube/rdb_mariadb_memcached/podman-kube.yaml>`

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


.. _localhost:8091: http://localhost:8091
.. _Docker: https://docs.docker.com/engine/install/
.. _compose: https://docs.docker.com/compose/install/
.. _podman-kube: https://docs.podman.io/en/latest/markdown/podman-kube.1.html
.. _ullgren: https://github.com/ullgren/rootdb-podman-infra
