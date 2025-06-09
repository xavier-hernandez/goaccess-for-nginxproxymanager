#!/bin/bash
source $(dirname "$0")/funcs/internal.sh
source $(dirname "$0")/funcs/environment.sh
source $(dirname "$0")/logs/npm.sh
source $(dirname "$0")/logs/npm_redirection.sh
source $(dirname "$0")/logs/npm_error.sh
source $(dirname "$0")/logs/traefik.sh
source $(dirname "$0")/logs/custom.sh
source $(dirname "$0")/logs/ncsa_combined.sh
source $(dirname "$0")/logs/nginx_access.sh
source $(dirname "$0")/logs/caddy.sh

goan_version="GOAN v1.1.36"
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

### COPY ORIGINAL BROWSERS LIST
original_browsers_list=/goaccess/config/browsers.list
browsers_list="/goaccess-config/browsers.list"
if [[ -f ${browsers_list} ]]; then
    rm ${browsers_list}
    cp ${original_browsers_list} ${browsers_list}
else
    cp ${original_browsers_list} ${browsers_list}
fi
### END COPYING BROWSERS LIST

### MODIFY BROWSERS LIST WITH USER'S CUSTOM BROWSERS
if [ ! -z "${CUSTOM_BROWSERS}" ]; then
    IFS=','
    read -ra BROWSER_CATEGORY <<< "$CUSTOM_BROWSERS"
    unset IFS
    for b_c in "${BROWSER_CATEGORY[@]}"; do
        IFS=':'
        read -ra BROWSER <<< "$b_c"
        if grep -Fwq "${BROWSER[0]}" ${browsers_list}
        then
            echo -e "\n\t${BROWSER[0]} ALREADY IN BROWSERS LIST"
        else
            echo -e "${BROWSER[0]}\t${BROWSER[1]}" >> ${browsers_list}
            echo -e "\n\t${BROWSER[0]} ADDED TO BROWSERS LIST"
        fi
    done
    unset IFS
else
    echo -e "\n\tCUSTOM_BROWSERS VARIABLE IS EMPTY"
fi
### END MODIFYING BROWSERS LIST

# BEGIN PROXY LOGS
if [[ -z "${LOG_TYPE}" || "${LOG_TYPE}" == "NPM" || "${LOG_TYPE}" == "NPM+R"  || "${LOG_TYPE}" == "NPM+ALL" ]]; then
    echo -e "\n\nNPM INSTANCE SETTING UP..."
    npm
    if [[ "${LOG_TYPE}" == "NPM+ALL" ]]; then
        echo -e "\n\nNPM REDIRECT INSTANCE SETTING UP..."
        npm_redirect
        echo -e "\n\nNPM ERROR INSTANCE SETTING UP..."
        npm_error
    elif [[ "${LOG_TYPE}" == "NPM+R" ]]; then
        echo -e "\n\nNPM REDIRECT INSTANCE SETTING UP..."
        npm_redirect
    fi
elif [[ "${LOG_TYPE}" == "TRAEFIK" ]]; then
    traefik
elif [[ "${LOG_TYPE}" == "NCSA_COMBINED" ]]; then
    ncsa_combined
elif [[ "${LOG_TYPE}" == "CUSTOM" ]]; then
    if [ -d "/opt/custom" ] && [ -w "/opt/custom" ]; then
        echo "Custom directory /opt/custom is available."
        custom
    else
        echo "Custom directory /opt/custom is not available. Exiting..."
        exit 1
    fi
elif [[ "${LOG_TYPE}" == "NGINX_ACCESS" ]]; then
    nginx_access
elif [[ "${LOG_TYPE}" == "CADDY_V1" ]]; then
    caddyV1 
fi
# END PROXY LOGS

#Leave container running
wait -n
