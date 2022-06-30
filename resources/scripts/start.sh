#!/bin/bash
source $(dirname "$0")/funcs/internal.sh
source $(dirname "$0")/funcs/environment.sh
source $(dirname "$0")/logs/npm.sh
source $(dirname "$0")/logs/npm_redirect.sh
source $(dirname "$0")/logs/traefik.sh

goan_version="GOAN v1.1.1"
goan_log_path="/opt/log"

echo -e "\n${goan_version}\n"

### NGINX
nginx_basic_auth

if [[ ! -d "/var/www/html" ]]; then
    mkdir /var/www/html
fi

tini -s -- nginx
### NGINX

# BEGIN PROXY LOGS
if [[ -z "${LOG_TYPE}" || "${LOG_TYPE}" == "NPM" ]]; then
    npm
elif [[ "${LOG_TYPE}" == "NPM-R" ]]; then
    npm
    npm_redirect
elif [[ "${LOG_TYPE}" == "TRAEFIK" ]]; then
    traefik
fi
# END PROXY LOGS

#Leave container running
tail -f /dev/null