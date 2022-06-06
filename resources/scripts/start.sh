#!/bin/bash
source $(dirname "$0")/funcs/internal.sh
source $(dirname "$0")/funcs/environment.sh

goan_version="GOAN v1.0.9"
goan_log_path="/opt/log"

echo -e "\n${goan_version}\n"

#Set NGINX basic authentication
nginx_basic_auth

# BEGIN PROXY LOGS
goan_proxy_config="/goaccess-config/goaccess_proxy.conf"
cp /goaccess-config/goaccess.conf ${goan_proxy_config}

mkdir /var/www/html
nginx_proxy_html="/var/www/html/index.html"
if [[ -f ${nginx_proxy_html} ]]; then
    rm ${nginx_proxy_html}
fi

proxy_html_config="/var/www/html/goaccess_conf.html"
if [[ -f ${proxy_html_config} ]]; then
    rm ${proxy_html_config}
fi

goan_proxy_archive_log="/goaccess-config/access_archive.log"
if [[ -f ${goan_proxy_archive_log} ]]; then
    rm ${goan_proxy_archive_log}
fi

set_proxy_config ${goan_proxy_config}
load_proxy_logs ${goan_log_path} ${goan_proxy_config} ${goan_proxy_archive_log} ${nginx_proxy_html}
exclude_ips ${goan_proxy_config}
debug ${proxy_html_config} ${goan_proxy_config}
# END PROXY LOGS

#RUN NGINX
tini -s -- nginx

#RUN GOACCESS
echo -e "\nRUN MAIN GOACCESS"
tini -s -- /goaccess/goaccess --daemonize --no-global-config --config-file=${goan_proxy_config}

#Leave container running
tail -f /dev/null