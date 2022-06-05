#!/bin/bash

#Exclude IPs
function exclude_ips() {
    echo -e "\nEXCLUDE_IPS"
    echo "-------------------------------"    
    if [[ -z "${EXCLUDE_IPS}" ]]
    then
        echo "None"
    else
        ips=""

        echo $'\n' >> /goaccess-config/goaccess.conf
        echo "#GOAN_EXCLUDE_IPS" >> /goaccess-config/goaccess.conf
        IFS=','
        read -ra ADDR <<< "$EXCLUDE_IPS"
        for ip in "${ADDR[@]}"; do
            echo ${ip}
            echo "exclude-ip ${ip}" >> /goaccess-config/goaccess.conf
        done
        unset IFS
    fi
}

#Set NGINX basic authentication
function nginx_basic_auth() {
    echo -e "\nNGINX BASIC AUTH"
    echo "-------------------------------"
    if [[ "${BASIC_AUTH}" == "True" ]]
    then
        echo "Setting up basic auth in NGINX..."
        if [[ -z "$BASIC_AUTH_USERNAME" || -z "$BASIC_AUTH_PASSWORD" ]]
        then
            echo "Username or password is blank or not set."
        else
            nginx_auth_basic_s="#goan_authbasic"
            nginx_auth_basic_r="auth_basic    \"GoAccess WebUI\";\n      auth_basic_user_file \/opt\/auth\/.htpasswd; \n"
            sed -i "s/$nginx_auth_basic_s/$nginx_auth_basic_r/" /etc/nginx/nginx.conf

            htpasswd -b /opt/auth/.htpasswd $BASIC_AUTH_USERNAME $BASIC_AUTH_PASSWORD
            echo "Done"
        fi
    else
        echo "None"
    fi

}

#ADD DEBUGGING
function debug() {
    echo -e "\nDEBUG"
    echo "-------------------------------"
    if [[ "${DEBUG}" == "True" ]]
    then
        proxy_config="/goaccess-config/goaccess.conf"
        proxy_html_config="/var/www/html/goaccess_conf.html"

        echo "ON"
        echo "<!doctype html><html><head>" > ${proxy_html_config}
        echo "<title>GoAccess for Nginx Proxy Manager Logs - ${goan_version}</title>" >> ${proxy_html_config}
        echo "<style>body{font-family:Arial,sans-serif;}code{white-space:pre-wrap;}</style>" >> ${proxy_html_config}
        echo "</head><body><code>" >> ${proxy_html_config}
        cat  ${proxy_config} >> ${proxy_html_config}
        echo "</code></body></html>" >> ${proxy_html_config}
    else
        echo -e "OFF"
    fi
}

#Find active logs and check for read access
function logs_load_archive() {
    touch ${goan_container_archive_log}

    if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
    then
        echo "Skipping archived logs as requested..."
    else
        if [[ -d "${1}" && -x "${1}" ]];
        then
            count=`ls -1 ${1}/proxy-host-*_access.log*.gz | wc -l`
            if [ $count != 0 ]
            then 
                echo "Loading (${count}) archived logs from ${1}..."
                zcat -f ${1}/proxy-host-*_access.log*.gz > ${goan_container_archive_log}
                echo  "log-file ${goan_container_archive_log}" >> ${goan_container_proxy_logs}
            else
                echo "No archived logs found at ${1}..."
            fi
            goan_proxy_archive_log_count=$((count))
        else
            echo "Problem loading directory (check directory or permissions)... ${1}"
        fi
    fi
}