#!/bin/bash
source $(dirname "$0")/funcs/nginx.sh
source $(dirname "$0")/funcs/internal.sh
source $(dirname "$0")/funcs/environment.sh

goan_version="GOAN v1.0.8"
goan_log_path="/opt/log"
goan_dir_valid=0 #false
goan_container_archive_log="/goaccess-config/access_archive.log"
goan_container_active_log="/goaccess-config/access.log"
goan_container_proxy_logs="/goaccess-config/proxy_logs"
goan_proxy_log_count=0
goan_proxy_archive_log_count=0

echo -e "\n${goan_version}\n"

#clean up
if [[ -f "$goan_container_proxy_logs" ]]; then
    rm ${goan_container_proxy_logs}
fi
if [[ -f "$goan_container_archive_log" ]]; then
    rm ${goan_container_archive_log}
fi
if [[ -f "$goan_container_active_log" ]]; then
    rm ${goan_container_active_log}
fi
if [[ -f "/goaccess-config/goaccess.conf" ]]; then
    cp /goaccess-config/goaccess.conf.bak /goaccess-config/goaccess.conf
fi

#Set NGINX basic authentication
nginx_basic_auth

#Load archived logs
logs_load_archive ${goan_log_path}

#Find active logs and check for read access
logs_load_active ${goan_log_path}

#Exclude IPs
exclude_ips

#Mods to index.html
nginx_image_version
nginx_processing_count

#RUN NGINX
tini -s -- nginx

#APPEND LOG FILE NAMES TO GOACCESS CONFIG
sed -i -e '/#GOAN_PROXY_FILES/r /goaccess-config/proxy_logs' /goaccess-config/goaccess.conf

#DEBUG
debug

#RUN GOACCESS
echo -e "\nProcessing ($((goan_proxy_log_count+goan_proxy_archive_log_count))) total log(s)...\n"
tini -s -- /goaccess/goaccess --no-global-config --config-file=/goaccess-config/goaccess.conf