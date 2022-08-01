#!/bin/bash
source $(dirname "$0")/funcs/internal.sh
source $(dirname "$0")/funcs/environment.sh
source $(dirname "$0")/logs/npm.sh
source $(dirname "$0")/logs/npm_redirection.sh
source $(dirname "$0")/logs/traefik.sh
source $(dirname "$0")/logs/custom.sh

goan_version="GOAN v1.1.2"
goan_log_path="/opt/log"

echo -e "\n${goan_version}\n"

### NGINX
echo -e "\nNGINX SETUP..."
nginx_basic_auth

if [[ ! -d "/var/www/html" ]]; then
    mkdir /var/www/html
fi

tini -s -- nginx
### NGINX

# BEGIN PROXY LOGS
if [[ -z "${LOG_TYPE}" || "${LOG_TYPE}" == "NPM" || "${LOG_TYPE}" == "NPM+R" ]]; then
    echo -e "\n\nNPM INSTANCE SETTING UP..."
    npm
    
    if [[ "${LOG_TYPE}" == "NPM+R" ]]; then
        echo -e "\n\nNPM REDIRECT INSTANCE SETTING UP..."
        npm_redirect
    fi
elif [[ "${LOG_TYPE}" == "TRAEFIK" ]]; then
    traefik
elif [[ "${LOG_TYPE}" == "CUSTOM" ]]; then
    custom
fi
# END PROXY LOGS

#Leave container running
tail -f /dev/null