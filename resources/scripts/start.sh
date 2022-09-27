#!/bin/bash
source $(dirname "$0")/funcs/internal.sh
source $(dirname "$0")/funcs/environment.sh
source $(dirname "$0")/logs/npm.sh
source $(dirname "$0")/logs/npm_redirection.sh
source $(dirname "$0")/logs/traefik.sh
source $(dirname "$0")/logs/custom.sh
source $(dirname "$0")/logs/ncsa_combined.sh

goan_version="GOAN v1.1.8"
goan_log_path="/opt/log"

goaccess_ping_interval=15
goaccess_debug_file=/goaccess-logs/goaccess.debug
goaccess_invalid_file=/goaccess-logs/goaccess.invalid

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
    if [[ "${LOG_TYPE}" == "NPM+R" ]]; then
        echo -e "\n\nNPM REDIRECT INSTANCE SETTING UP..."
        npm_redirect
    fi
    
    echo -e "\n\nNPM INSTANCE SETTING UP..."
    npm
elif [[ "${LOG_TYPE}" == "TRAEFIK" ]]; then
    traefik
elif [[ "${LOG_TYPE}" == "NCSA_COMBINED" ]]; then
    ncsa_combined
elif [[ "${LOG_TYPE}" == "CUSTOM" ]]; then
    custom
fi
# END PROXY LOGS

#Leave container running
wait -n