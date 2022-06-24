#!/bin/bash
source $(dirname "$0")/funcs/internal.sh
source $(dirname "$0")/funcs/environment.sh

goan_version="GOAN v1.1.0"
goan_log_path="/opt/log"

echo -e "\n${goan_version}\n"

#Set NGINX basic authentication
nginx_basic_auth

# SETUP HTML FOLDER FOR NGINX
if [[ ! -d "/var/www/html" ]]; then
    mkdir /var/www/html
fi

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

#Leave container running
tail -f /dev/null