===============
Troubleshooting
===============

Error with TLS certificate
==========================

.. list-table:: Common errors that can occurs
   :widths: 40 10 50
   :header-rows: 1

   * - Error
     - Where can I see it ?
     - Probable cause
   * - ``Pusher error: cURL error 35: error:14094410:SSL routines:ssl3_read_bytes:sslv3 alert handshake failure``
     - Web-browser developer tools
     - Make  sure SSL certificates are readable by nginx process user. ( ``www-data:www-data`` on Debian based distro )
   * - ``cURL error 60: SSL certificate problem: unable to get local issuer certificate``
     - Web-browser developer tools
     - ``WEBSOCKETS_SSL_LOCAL_CERT`` in API ``.env`` file have to be a fullchain.pem file
   * - ``cURL error 60: SSL: no alternative certificate subject name matches target host name '127.0.0.1'``
     - Web-browser developer tools
     - ``PUSHER_APP_HOST`` from ``.app-config.js`` does not match  ``SESSION_DOMAIN`` from API ``.env``
   * - ``<a_webbrowser> cannot establish a connection with the server at address wss://<your_api_hostname>:6001/app/<you_ws_public_key>?protocol=7&client=js&version=7.4.0&flash=false``
     - Web-browser developer tools
     - | If you use a TLS connection for websocket, make sure that ``LARAVEL_WEBSOCKETS_SSL_LOCAL_CERT`` and ``LARAVEL_WEBSOCKETS_SSL_LOCAL_PK``  point to up-to-date files, with right permissions. (``-rw-r--r--`` for ``LOCAL_CERT``, and ``-rw-------`` for ``LOCAL_PK`` )

        .. code-block:: bash

            chmod 644 <LOCAL_CERT>
            chmod 600 <LOCAL_PK>

   * - ``Websocket server is not working. ["[object] (Illuminate\\Broadcasting\\BroadcastException(code: 0): Pusher error: {\"error\":\"Unknown app id rootdb-api-pusher-app-id-0911ce49ed05fca9b8581329cb3a83730922c238 provided.\"}``
     - `api/storage/logs/laravel.log`
     - It means that PHP is unable to reach the websocket server. Make sure it's running or, if it's running correctly, make sure that ``PUSHER_APP_HOST=your_api_hostname`` is reachable.


Where are the log ?
===================

If RootDB was installed without Docker
--------------------------------------

You'll find log files here :

.. code-block::

    /path/to/rootdb/www/api/storage/logs
    ├── laravel.log
    ├── websocket.log
    └── worker.log


If RootDB was installed with Docker, but `www` directory is mounted
-------------------------------------------------------------------

You'll find log files here :

.. code-block::

    /path/to/rootdb/mounted_www/api/storage/logs
    ├── laravel.log
    ├── websocket.log
    └── worker.log

If RootDB was installed with Docker, and `www` directory is not mounted
-----------------------------------------------------------------------

.. code-block:: bash

    # Each log files :
    docker exec -u rootdb -it rootdb bash -c 'less -R var/www/api/storage/logs/laravel.log'
    docker exec -u rootdb -it rootdb bash -c 'less -R var/www/api/storage/logs/websocket.log'
    docker exec -u rootdb -it rootdb bash -c 'less -R var/www/api/storage/logs/worker.log'

    # All log files :
    docker exec -u rootdb -it rootdb bash -c 'less -R var/www/api/storage/logs/*.log'
