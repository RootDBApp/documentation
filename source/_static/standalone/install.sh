#!/usr/bin/env bash

# clear && ./install.sh

###############################################################################################
declare SCRIPT_PATH
pushd . >/dev/null
SCRIPT_PATH="${BASH_SOURCE[0]}"
if ([ -h "${SCRIPT_PATH}" ]); then
  while ([ -h "${SCRIPT_PATH}" ]); do
    cd "$(dirname "$SCRIPT_PATH")" || exit
    SCRIPT_PATH=$(readlink "${SCRIPT_PATH}")
  done
fi
cd "$(dirname ${SCRIPT_PATH})" || exit >/dev/null
SCRIPT_PATH=$(pwd)
popd || exit >/dev/null
###############################################################################################

declare txtblue="\\033[1;34m"
declare txtgreen="\\033[1;32m"
declare txtnormal="\\033[0;39m"
declare txtred="\\033[1;31m"
declare txtyellow="\\033[1;33m"

# @param 1 string  - log string
# @param 2 boolean - false, with carriage return. true, without carriage return
function logInfo() {

  if [[ ! $2 ]]; then

    echo -e "${txtyellow}log${txtnormal} | $1"
  else

    echo -en "${txtyellow}log${txtnormal} | $1"
  fi
}

# Append [ OK ] to the end of current line
function logInfoAddOK() {

  echo -e "[${txtgreen}OK${txtnormal}]" || logInfo "[OK]"
}

# Append [ Fail ] to the end of current line
function logInfoAddFail() {

  echo -e "[${txtred}Fail${txtnormal}]" || logInfo "[Fail]"
}

# @param 1 - error string
function logError() {

  echo -e "${txtred}error${txtnormal} | $1"
}

function logQuestion() {

  echo -en "${txtblue}log${txtnormal} | $1"
}

# @param 1 - path
function getUser() {
  stat -c '%U' "$1"
}

# @param 1 - path
function getGroup() {
  stat -c '%G' "$1"
}

###############################################################################################

declare env_file="${SCRIPT_PATH}/.env"
declare error=false
declare ignore_software_dependencies=false
declare ignore_mariadb_db_and_user_setup=false

# From .env file
declare version
declare data_dir
declare session_domain
declare scheme
declare front_host
declare api_host
declare api_memcached_host
declare api_memcached_port
declare api_db_host
declare api_db_port
declare api_db_root_password
declare api_db_user_password
declare nginx_user
declare nginx_group
declare pusher_app_key
declare websockets_port
declare websockets_ssl_local_cert
declare websockets_ssl_local_pk
declare websockets_ssl_passphrase

function help() {

  echo "$0 [OPTIONS]"
  echo
  echo "This script will install RootDB : "
  echo "1 - check if software dependencies are available."
  echo "2 - download RootDB archive."
  echo "3 - extract the archive and boostrap it."
  echo
  echo "At least, memcached and mariadb should be setup."
  echo
  echo "/!\ This script does not handle the configuration of :"
  echo "* nginx      : https://documentation.rootdb.fr/install/install_without_docker.html#nginx"
  echo "* memcached"
  echo "* php-fpm    : https://documentation.rootdb.fr/install/install_without_docker.html#php-fpm"
  echo "* mariadb    : https://documentation.rootdb.fr/install/install_without_docker.html#mariadb"
  echo "* supervisor : https://documentation.rootdb.fr/install/install_without_docker.html#supervisor"
  echo
  echo "Options:"
  echo -e "\t-i        - ignore software dependencies checks."
  echo -e "\t-m        - ignore MariaDB database creation and API user setup."
  echo
  echo -e "\t-e <.env> - .env file (default: ${env_file})"
  echo -e "\t            get a default .env file here : https://documentation.rootdb.fr/install/install_without_docker.html#how-to-get-the-code"
  echo
  echo -e "\t-h        - display this help and quit."
  echo
  exit 0
}

while getopts e:imh option; do
  case "${option}" in
  e) env_file=${OPTARG} ;;
  i) ignore_software_dependencies=true ;;
  m) ignore_mariadb_db_and_user_setup=true ;;
  h) help ;;
  *) logInfo "Unrecognized option." ;;
  esac
done

#
#
# Checks
#
#
logInfo "Checks..."

if [[ "$(whoami)" != "root" ]]; then

  echo
  logError "you have to be \`root\` user in order to run this script."
  echo
  echo
  help
fi

# .env file
if [[ ! -f "${env_file}" ]]; then
  error=true
  logError ".env file \"${env_file}\" does not exists."
  logError "you need to provide a .env file with \"-e\" option"
  logInfo "get a default one here : https://document.rootdb.fr/.env"
  exit 1
fi

# software dependencies & php modules
if [[ ${ignore_software_dependencies} == false ]]; then

  declare software_checks_failed=false
  logInfo "Check software dependencies..." true
  declare commands="awk bunzip2 col curl memcached mysql mysqldump pgrep php sed semver supervisorctl tar"
  for command_looped in ${commands}; do
    type -P "${command_looped}" &>/dev/null && continue || {
      error=true
      [[ ${software_checks_failed} == false ]] && logInfoAddFail
      software_checks_failed=true
      logError "missing software : ${command_looped}"
    }
  done

  [[ ${software_checks_failed} == false ]] && logInfoAddOK

  declare php_modules_checks_failed=false
  logInfo "Check PHP modules..." true
  declare php_modules="bcmath curl ctype dom gd gettext iconv mbstring memcached pcntl pdo sourceguardian zip"

  for php_module_looped in ${php_modules}; do
    if [[ -z $(php -r "echo extension_loaded('${php_module_looped}') ? 'ok' : 'ko';" | grep 'ok') ]]; then
      error=true
      [[ ${php_modules_checks_failed} == false ]] && logInfoAddFail
      php_modules_checks_failed=true
      logError "missing PHP module : ${php_module_looped}"
    fi
  done

  [[ ${php_modules_checks_failed} == false ]] && logInfoAddOK

fi

if [[ ${error} == true || software_checks_failed == true || php_modules_checks_failed == true ]]; then
  logError "There are errors, stopping here."
  exit 1
fi

#
#
# Handling .env file
#
#
# Get variables from .env file...
logInfo "Check .env file contents..."
version=$(grep "VERSION" "${env_file}" | sed "s/VERSION=//")
data_dir=$(grep "DATA_DIR" "${env_file}" | sed "s/DATA_DIR=//")
scheme=$(grep "SCHEME" "${env_file}" | sed "s/SCHEME=//")
front_host=$(grep "FRONT_HOST" "${env_file}" | sed "s/FRONT_HOST=//")
api_host=$(grep "API_HOST" "${env_file}" | sed "s/API_HOST=//")
session_domain=$(awk -F/ '{n=split($3, a, "."); printf("%s.%s", a[n-1], a[n])}' <<<"${scheme}://$front_host")
api_memcached_host=$(grep "API_MEMCACHED_HOST" "${env_file}" | sed "s/API_MEMCACHED_HOST=//")
api_memcached_port=$(grep "API_MEMCACHED_PORT" "${env_file}" | sed "s/API_MEMCACHED_PORT=//")
api_db_host=$(grep "API_DB_HOST" "${env_file}" | sed "s/API_DB_HOST=//")
api_db_port=$(grep "API_DB_PORT" "${env_file}" | sed "s/API_DB_PORT=//")
api_db_root_password=$(grep "API_DB_ROOT_PASSWORD" "${env_file}" | sed "s/API_DB_ROOT_PASSWORD=//")
api_db_user_password=$(grep "API_DB_USER_PASSWORD" "${env_file}" | sed "s/API_DB_USER_PASSWORD=//")
api_db_limit_to_ip=$(grep "API_DB_LIMIT_TO_IP" "${env_file}" | sed "s/API_DB_LIMIT_TO_IP=//")
nginx_user=$(grep "NGINX_USER" "${env_file}" | sed "s/NGINX_USER=//")
nginx_group=$(grep "NGINX_GROUP" "${env_file}" | sed "s/NGINX_GROUP=//")
pusher_app_key=$(grep "^PUSHER_APP_KEY" "${env_file}" | sed "s/PUSHER_APP_KEY=//")
#websockets_port=$(grep "WEBSOCKETS_PORT" "${env_file}" | sed "s/WEBSOCKETS_PORT=//")
websockets_port=6001

websockets_ssl_local_cert=$(grep "WEBSOCKETS_SSL_LOCAL_CERT" "${env_file}" | sed "s/WEBSOCKETS_SSL_LOCAL_CERT=//")
websockets_ssl_local_pk=$(grep "WEBSOCKETS_SSL_LOCAL_PK" "${env_file}" | sed "s/WEBSOCKETS_SSL_LOCAL_PK=//")
websockets_ssl_passphrase=$(grep "WEBSOCKETS_SSL_PASSPHRASE" "${env_file}" | sed "s/WEBSOCKETS_SSL_PASSPHRASE=//")

logInfo "Extracted from the .env file :"
logInfo
logInfo "version                   : ${version}"
logInfo "data dir                  : ${data_dir}"
logInfo "scheme                    : ${scheme}"
logInfo "api host                  : ${api_host}"
logInfo "front host                : ${front_host}"
logInfo "session domain            : ${session_domain}"
logInfo "api_memcached_host        : ${api_memcached_host}"
logInfo "api_memcached_port        : ${api_memcached_port}"
logInfo "api db host               : ${api_db_host}"
logInfo "api db port               : ${api_db_port}"
logInfo "api db root password      : ${api_db_root_password}"
logInfo "api db user password      : ${api_db_user_password}"
logInfo "nginx user                : ${nginx_user}"
logInfo "nginx group               : ${nginx_group}"
logInfo "pusher app key            : ${pusher_app_key}"
logInfo "websockets port           : ${websockets_port}"

if [[ "$scheme" == "https" ]]; then
  logInfo "websockets ssl local_cert : ${websockets_ssl_local_cert}"
  logInfo "websockets ssl local pk   : ${websockets_ssl_local_pk}"
  logInfo "websockets ssl passphrase : ${websockets_ssl_passphrase}"
fi

echo
logQuestion "Is it OK ? [y/n] (default: y) "
read -r env_ok
echo

[[ -z "${env_ok}" ]] && env_ok="y"

if [[ "${env_ok}" != "y" ]]; then
  logInfo "Stopping here."
  exit 0
fi

#
#
# Latest checks
#
#
# Install directory
logInfo "Check install directory..." true
if [[ ! -d "${data_dir}" ]]; then
  error=true
  logInfoAddFail
  logError "install directory \"${data_dir}\" does not exists."
else
  logInfoAddOK
fi

# directories & permissions
logInfo "Check permissions..." true
if [[ ! -w "${data_dir}" ]]; then
  error=true
  logInfoAddFail
  logError "no write access to : ${data_dir}"
else
  logInfoAddOK
fi

# mariadb connexion
logInfo "Check mariadb connexion..." true
if [[ $(mysql -h "${api_db_host}" -u root -p${api_db_root_password} -e ";") ]]; then
  error=true
  logInfoAddFail
  logError "Unable to connect to MariaDB server."
else
  logInfoAddOK
fi

# memcached connexion
logInfo "Check memcached connexion..." true
declare -i test_res
test_res=$(php -r "\$c = new Memcached(); \$c->addServer(\"${api_memcached_host}\", ${api_memcached_port}); var_dump(\$c->getStats());" | grep 'array' | wc -l)
if [[ ${test_res} -eq 0 ]]; then
  error=true
  logInfoAddFail
  logError "Unable to connect to memcached server."
else
  logInfoAddOK
fi

# SSL stuff
logInfo "Check if ${websockets_ssl_local_cert} exists..." true
if [[ ! -f "${websockets_ssl_local_cert}" ]]; then
  error=true
  logInfoAddFail
  logError "File ${websockets_ssl_local_cert} does not exists."
else
  logInfoAddOK
fi

logInfo "Check if ${websockets_ssl_local_pk} exists..." true
if [[ ! -f "${websockets_ssl_local_pk}" ]]; then
  error=true
  logInfoAddFail
  logError "File ${websockets_ssl_local_pk} does not exists."
else
  logInfoAddOK
fi

if [[ ${error} == true ]]; then
  logInfo "There are errors, stopping here."
  exit 1
fi

#
#
# RooDB installation and boostrap
#
#
logInfo "RootDB installation..."
declare archive_file="rootdb-$version.tar.bz2"
declare rdb_archive_version_name
declare rdb_archives_dir="${data_dir}/archives"
declare rdb_archive_version
declare rdb_version_dir
declare frontend_dir="${data_dir}/frontend"
declare api_dir="${data_dir}/api"
declare front_dir="${data_dir}/frontend"
declare api_frontend_themes_dir="${api_dir}/frontend-themes"
declare api_env_file="${api_dir}/.env"
declare front_app_config_js_file="${front_dir}/app-config.js"
declare root_api_env_file="${data_dir}/.api_env"
declare root_front_app_config_js_file="${data_dir}/.app-config.js"
declare api_db_init_file="${data_dir}/.api_db_initialized"
declare api_init_file="${data_dir}/.api_initialized"
declare front_init_file="${data_dir}/.front_initialized"

declare rdb_init_file="${data_dir}/.rdb_initialized"

cd "${data_dir}" || exit 1

[[ ! -d "${rdb_archives_dir}" ]] && mkdir "${rdb_archives_dir}"
if [[ ! -d "${rdb_archives_dir}" ]]; then
  logError "Unable to create archive directory: ${rdb_archives_dir}"
  cd "${SCRIPT_PATH}" || exit 1
  exit 1
fi

logInfo "Downloading RootDB... ( ${archive_file} )"
curl -O "https://builds.rootdb.fr/rootdb/${archive_file}"

logInfo "Getting RootDB version from downloaded archive..."
rdb_archive_version=$(tar -tjf "${archive_file}" | cut -f1 -d"/" | sort | uniq)
rdb_archive_version_name="rootdb-${rdb_archive_version}.tar.bz2"
mv "${archive_file}" "${rdb_archive_version_name}"

rdb_version_dir="${rdb_archives_dir}/${rdb_archive_version}"
logInfo "Archive RootDB version : ${rdb_archive_version}"

[[ -d "${rdb_version_dir}" ]] && rm -Rf "${rdb_version_dir}"
logInfo "Extracting code... ( in ${rdb_archives_dir} ) "
tar -xjf "${rdb_archive_version_name}" -C "${rdb_archives_dir}"
logInfo "Archive directory for ${rdb_archive_version}: ${rdb_version_dir}"

if [[ ! -d "${rdb_archives_dir}" ]]; then
  logError "Issue while extracting the archive"
  cd "${SCRIPT_PATH}" || exit 1
  exit 1
fi

logInfo "Deleting downloaded archive..."
rm -f "${rdb_archive_version_name}"

#
#
# Configuration
#
#
logInfo "Creating symlinks..."
rm -f "${api_dir}"
rm -f "${frontend_dir}"
# from early version, we should be able to remove it now.
[[ -d "${api_frontend_themes_dir}" ]] && rm -Rf "${api_frontend_themes_dir}"
rm -f "${api_frontend_themes_dir}"

ln -s "${rdb_version_dir}/api" "${api_dir}"
ln -s "${rdb_version_dir}/frontend" "${frontend_dir}"
ln -s "${rdb_version_dir}/frontend/themes" "${api_frontend_themes_dir}"

logInfo "[API] Handling .env file..."
[[ -f "${root_api_env_file}" ]] && rm -f "${root_api_env_file}"

logInfo "[API] Copy ${rdb_version_dir}/api/.env -> ${root_api_env_file}"
cp "${rdb_version_dir}/api/.env" "${root_api_env_file}"

rm -f "${rdb_version_dir}/api/.env"

logInfo "[API] Link ${root_api_env_file} -> ${api_env_file}"
ln -s "${root_api_env_file}" "${api_env_file}"

#echo "${rdb_archive_version}" > "${data_dir}/.version"

touch "${api_init_file}"

logInfo "[Front] Handling app-config.js file..."
[[ -f "${root_front_app_config_js_file}" ]] && rm -f "${root_front_app_config_js_file}"

logInfo "[Front] Copy ${rdb_version_dir}/frontend/app-config.js -> ${root_front_app_config_js_file}"
cp "${rdb_version_dir}/frontend/app-config.js" "${root_front_app_config_js_file}"

rm -f "${rdb_version_dir}/frontend/app-config.js"

logInfo "[Front] Link ${root_front_app_config_js_file} -> ${front_app_config_js_file}"
ln -s "${root_front_app_config_js_file}" "${front_app_config_js_file}"

touch "${front_init_file}"

if [[ ${ignore_mariadb_db_and_user_setup} == false ]]; then

  logInfo "[API] Database setup..."
  declare test_db_setup=$(mysql -h "${api_db_host}" -u root -p${api_db_root_password} -e "SHOW DATABASES LIKE 'rootdb-api';")
  if [[ -z ${test_db_setup} ]]; then

    mysql -h "${api_db_host}" -u root -p${api_db_root_password} -e "CREATE DATABASE \`rootdb-api\`; GRANT USAGE ON \`rootdb-api\`.* TO 'rootdb_api_user'@'${api_db_limit_to_ip}' IDENTIFIED BY '${api_db_user_password}'; GRANT SELECT, CREATE, INSERT, UPDATE, DELETE, DROP, INDEX, ALTER, SHOW VIEW  ON \`rootdb-api\`.* TO 'rootdb_api_user'@'${api_db_limit_to_ip}';"
    if [[ $? -eq 1 ]]; then
      logError "Unable to initialize RootDB user."
      cd "${SCRIPT_PATH}" || exit 1
      exit 1
    fi
  else
    logInfo "[API] Database already created."
  fi
fi

logInfo "[API] Environment configuration ..."
declare -A env_var_to_api_vars=()
env_var_to_api_vars[DB_HOST]="${api_db_host}"
env_var_to_api_vars[DB_PORT]="${api_db_port}"
env_var_to_api_vars[DB_PASSWORD]="${api_db_user_password}"
env_var_to_api_vars[DB_HOST]="${api_db_host}"
env_var_to_api_vars[MEMCACHED_HOST]="${api_memcached_host}"
env_var_to_api_vars[MEMCACHED_PORT]="${api_memcached_port}"
env_var_to_api_vars[APP_URL]="${scheme}://${api_host}"
env_var_to_api_vars[SESSION_DOMAIN]="${session_domain}"
env_var_to_api_vars[SANCTUM_STATEFUL_DOMAINS]="${session_domain}"
env_var_to_api_vars[PUSHER_APP_KEY]="${pusher_app_key}"
env_var_to_api_vars[PUSHER_APP_SCHEME]="${scheme}"
env_var_to_api_vars[PUSHER_APP_HOST]="${api_host}"
env_var_to_api_vars[PUSHER_APP_ALLOWED_ORIGINS]="${api_host},${front_host},${session_domain}"
env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_LOCAL_CERT]=""
env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_LOCAL_PK]=""
env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_PASSPHRASE]=""

if [[ "${scheme}" == "https" ]]; then
  env_var_to_api_vars[PUSHER_APP_USE_TLS]="true"
  env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_LOCAL_CERT]="${websockets_ssl_local_cert}"
  env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_LOCAL_PK]="${websockets_ssl_local_pk}"
  env_var_to_api_vars[LARAVEL_WEBSOCKETS_SSL_PASSPHRASE]="${websockets_ssl_passphrase}"
fi

for env_var_idx in "${!env_var_to_api_vars[@]}"; do

  declare var_name="${env_var_idx}"
  declare var_value="${env_var_to_api_vars[$env_var_idx]}"

  if [[ ! -z "${var_value}" ]]; then

    sed -i "s|${var_name}=\(.*\)|${var_name}=${var_value}|g" "${data_dir}/.api_env"
  fi
done

logInfo "[API] Database initialization..."
echo
logQuestion "\`root-db\` schema will be wiped, is it OK ? [y/n] (default: y) "
read -r env_ok
echo

[[ -z "${env_ok}" ]] && env_ok="y"

if [[ "${env_ok}" == "y" ]]; then
  mysql -h "${api_db_host}" -u root -p${api_db_root_password} "rootdb-api" <"${api_dir}/storage/app/seeders/production/seeder_init.sql"

  logInfo "[API] Database initialized."
else
  logInfo "Skipping database initialization."
fi

logInfo "[Front] Environment configuration ..."
declare -A env_var_to_front_vars=()
env_var_to_front_vars[REACT_APP_API_URL]="${scheme}://${api_host}"
env_var_to_front_vars[REACT_APP_ECHO_CLIENT_KEY]="${pusher_app_key}"
env_var_to_front_vars[REACT_APP_ECHO_CLIENT_CLUSTER]="$(grep "^PUSHER_APP_CLUSTER" "${data_dir}/.api_env" | sed "s/PUSHER_APP_CLUSTER=//")"
env_var_to_front_vars[REACT_APP_ECHO_CLIENT_WS_HOST]="${api_host}"
env_var_to_front_vars[REACT_APP_ECHO_CLIENT_WS_PORT]="${websockets_port}"
env_var_to_front_vars[REACT_APP_ECHO_CLIENT_WSS_HOST]="${api_host}"
env_var_to_front_vars[REACT_APP_ECHO_CLIENT_WSS_PORT]="${websockets_port}"
if [[ "${scheme}" == "https" ]]; then
  env_var_to_front_vars[REACT_APP_ECHO_CLIENT_FORCE_TLS]="true"
fi

for env_var_idx in "${!env_var_to_front_vars[@]}"; do

  declare var_name="${env_var_idx}"
  declare var_value="${env_var_to_front_vars[$env_var_idx]}"

  if [[ ! -z "${var_value}" ]]; then

    sed -i "s|\(.*${var_name}.*\)|'${var_name}': '${var_value}',|g" "${data_dir}/.app-config.js"
  fi
done

sed -i "s|\(.*REACT_APP_ECHO_CLIENT_AUTHENDPOINT.*\)|'REACT_APP_ECHO_CLIENT_AUTHENDPOINT'\: '${scheme}://${api_host}\/broadcasting\/auth',|g" "${data_dir}/.app-config.js"

logInfo "Setup permissions..."
chown -R ${nginx_user}:${nginx_group} "${data_dir}"
if [[ "${scheme}" == "https" ]]; then
  chown ${nginx_user}:${nginx_group} "${websockets_ssl_local_cert}"
  chmod 644 "${websockets_ssl_local_cert}"
  chown ${nginx_user}:${nginx_group} "${websockets_ssl_local_pk}"
  chmod 600 "${websockets_ssl_local_pk}"
fi

logInfo "RootDB is initialized."
echo
touch "${api_db_init_file}"
touch "${rdb_init_file}"

logInfo "You should start (or restart) supervisor, php-fpm, nginx"
logInfo "For instance :"
logInfo "systemctl restart php8.1-fpm"
logInfo "systemctl restart supervisor"
logInfo "systemctl restart nginx"

cd "${SCRIPT_PATH}" || exit 1
