#!/usr/bin/env bash

wget "https://raw.githubusercontent.com/RootDBApp/infra/main/bash/install.sh"
wget "https://raw.githubusercontent.com/RootDBApp/infra/main/bash/env"
wget "https://raw.githubusercontent.com/RootDBApp/infra/main/nginx/rootdb-api.hostname.tld"
wget "https://raw.githubusercontent.com/RootDBApp/infra/main/nginx/rootdb-frontend.hostname.tld"
wget "https://raw.githubusercontent.com/RootDBApp/infra/main/supervisor/rootdb-cron_scheduler.conf"
wget "https://raw.githubusercontent.com/RootDBApp/infra/main/supervisor/rootdb-websocket_server.conf"

md5sum install.sh
md5sum env
md5sum rootdb-api.hostname.tld
md5sum rootdb-frontend.hostname.tld
md5sum rootdb-cron_scheduler.conf
md5sum rootdb-websocket_server.conf


rm -f install.sh env rootdb-api.hostname.tld rootdb-frontend.hostname.tld rootdb-cron_scheduler.con rootdb-websocket_server.conf
