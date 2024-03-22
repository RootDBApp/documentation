=================
Local development
=================

------------
Requirements
------------

| * A directory named, for instance, ``rootdb``, that will contains all code.
| * `Docker`_ up & running. (with ``docker compose`` plugin installed too)
| * For the frontend development you should have installed on your workstation :
|    * the latest version of `Node.js`_
|    * the latest version of `Yarn`_

Finally, you have to update your system ``hosts`` file and add these entries :

.. list-table:: All entries to setup in your ``hosts`` file
   :widths: 60 40
   :header-rows: 1

   * - Hostname
     - IPv4 address
   * - ``dev-rootdb-api.localhost.com``
     - ``172.20.0.40``
   * - ``dev-rootdb-ws-api.localhost.com``
     -  ``172.20.0.30``
   * - ``dev-rootdb-frontend.localhost.com``
     -  ``127.0.0.1``

------------
Get the code
------------

First step, you have to get the code from these Github repositories, to store in you ``rootdb`` local directory :

1. Infrastructure code, containing docker images for local development : `github.com/RootDBApp/infra`_
2. API code : `github.com/RootDBApp/api`_
3. Frontend code : `github.com/RootDBApp/frontend`_

You should have something like that in your ``rootdb`` directory :

.. code-block:: bash

    .
    ├── api
    ├── frontend
    └── infra

--------------------------
Start development services
--------------------------


Frontend
--------

| It's a usual React webapp, so you simply need to start the development server.
| Go inside the ``frontend`` main directory and start it like this :

.. code-block:: bash

    $ yarn install
    $ yarn start-dev

    [...]
    Compiled successfully!

    You can now view rootdb in the browser.

      http://dev-rootdb-frontend.localhost.com:3000

    Note that the development build is not optimized.
    To create a production build, use yarn build.

    webpack compiled successfully
    No issues found.


.. tip::

    At this point, since API services are not yet started, the display of the frontend is broken, that's normal :)

API
---

| For the API, all is containerized with Docker. (MariaDB, Nginx, PHP-FPM, Memcached & Supervisor).
| In a terminal, go inside ``infra/docker-compose-dev/rdb_mariaddb_memcached`` and start services with :

.. code-block:: bash

    $ user=rootdb  docker compose up

    [...]
    dev-rootdb-api        |
    dev-rootdb-api        |    INFO  Nothing to migrate.
    dev-rootdb-api        |
    dev-rootdb-api        | Starting services with supervisor...
    dev-rootdb-api        | [22-Mar-2024 09:40:04] NOTICE: fpm is running, pid 1
    dev-rootdb-api        | [22-Mar-2024 09:40:04] NOTICE: ready to handle connections
    dev-rootdb-api        | [22-Mar-2024 09:40:04] NOTICE: systemd monitor interval set to 10000ms


| And that's all.
| You can now refresh your web browser, that should already be opened on `dev-rootdb-frontend.localhost.com:3000`_ and RootDB should be displayed correctly.


.. tip::

    If you need to run ``composer``, ``supervisor``, or Laravel ``artisan`` command, you have to go inside the API container :

    .. code-block:: bash

        $ docker exec -it dev-rootdb-api bash


.. _github.com/RootDBApp/infra: https://github.com/RootDBApp/infra
.. _github.com/RootDBApp/api: https://github.com/RootDBApp/api
.. _github.com/RootDBApp/frontend: hhttps://github.com/RootDBApp/frontend
.. _Docker: https://docs.docker.com/engine/install/
.. _Node.js: https://nodejs.org/en
.. _Yarn: https://yarnpkg.com/
.. _dev-rootdb-frontend.localhost.com\:3000: http://dev-rootdb-frontend.localhost.com:3000