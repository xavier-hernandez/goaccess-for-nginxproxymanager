#!/bin/bash
source $(dirname "$0")/funcs/internal.sh
source $(dirname "$0")/funcs/environment.sh
source $(dirname "$0")/logs/npm.sh
source $(dirname "$0")/logs/npm_redirection.sh
source $(dirname "$0")/logs/traefik.sh
source $(dirname "$0")/logs/custom.sh

<<<<<<< HEAD
goan_version="GOAN v1.1.0"
=======
goan_version="GOAN v1.1.1"
>>>>>>> develop
goan_log_path="/opt/log"

echo -e "\n${goan_version}\n"

### NGINX
echo -e "\nNGINX SETUP..."
nginx_basic_auth

if [[ ! -d "/var/www/html" ]]; then
    mkdir /var/www/html
fi

<<<<<<< HEAD
# CLEAN UP
goan_config="/goaccess-config/goaccess.conf"
cp /goaccess-config/goaccess.conf.bak ${goan_config}

nginx_html="/var/www/html/index.html"
if [[ -f ${nginx_html} ]]; then
    rm ${nginx_html}
fi

html_config="/var/www/html/goaccess_conf.html"
if [[ -f ${html_config} ]]; then
    rm ${html_config}
fi
# END OF CLEAN UP

# BEGIN PROXY LOGS
if [[ -z "${LOG_TYPE}" || "${LOG_TYPE}" == "NPM" ]]; then
    goan_proxy_archive_log="/goaccess-config/access_archive.log"
    if [[ -f ${goan_proxy_archive_log} ]]; then
    rm ${goan_proxy_archive_log}
    fi

    set_npm_proxy_config ${goan_config}
    load_proxy_logs ${goan_log_path} ${goan_config} ${goan_proxy_archive_log} ${nginx_html}
elif [[ "${LOG_TYPE}" == "TRAEFIK" ]]; then
    set_traefik_config ${goan_config}
    load_traefik_logs ${goan_log_path} ${goan_config} ${nginx_html}
fi
# END PROXY LOGS

# BEGIN GLOBAL SETTINGS
exclude_ips             ${goan_config}
debug                   ${goan_config} ${html_config}
set_geoip_database      ${goan_config}
# END GLOBAL SETTINGS

#RUN NGINX
tini -s -- nginx

#RUN GOACCESS
echo -e "\nRUN MAIN GOACCESS"
tini -s -- /goaccess/goaccess --daemonize --no-global-config --config-file=${goan_config}

=======
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

>>>>>>> develop
#Leave container running
tail -f /dev/null