#!/bin/bash
source $(dirname "$0")/funcs/nginx.sh
source $(dirname "$0")/funcs/logs.sh

goan_version="GOAN v1.0.4"
goan_log_path="/opt/log"
goan_dir_valid=0 #false
goan_proxy_host=""
goan_container_archive_log="/goaccess/access_archive.log"
goan_container_active_log="/goaccess/access.log"
goan_proxy_log_count=0
goan_proxy_archive_log_count=0

echo -e "\n${goan_version}\n"

#Set NGINX basic authentication
nginx_basic_auth

#Load archived logs
logs_load_archive ${goan_log_path}

#Find active logs and check for read access
logs_load_active ${goan_log_path}

#Mods to index.html
nginx_image_version
nginx_processing_count

#RUN NGINX
tini -s -- nginx

#RUN GOACCESS
echo -e "\nProcessing ($((goan_proxy_log_count+goan_proxy_archive_log_count))) total log(s)...\n"
tini -s -- /goaccess/goaccess ${goan_container_archive_log} ${goan_proxy_host} --no-global-config --config-file=/goaccess-config/goaccess.conf