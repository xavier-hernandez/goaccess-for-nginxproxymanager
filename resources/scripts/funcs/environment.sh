#!/bin/bash

#Exclude IPs
function exclude_ips() {
    if [[ -z "${EXCLUDE_IPS}" ]]
    then
        //no excluded ips
    else
        echo -e "\nExcluding IPs..."
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
        fi
    fi
}

#ADD DEBUGGING
function debug() {
    if [[ "${DEBUG}" == "True" ]]
    then
        echo -e "\nDEBUG - ON"
        cp /goan/debug/goaccess_conf.html /var/www/html/goaccess_conf.html

        src="#goan_version"
        rpl=${goan_version}
        sed -i "s/$src/$rpl/" /var/www/html/goaccess_conf.html

        sed -i -e '/#GOAN_INPUT/r /goaccess-config/goaccess.conf' /var/www/html/goaccess_conf.html
        sed -i -e 's/#GOAN_INPUT//' /var/www/html/goaccess_conf.html
    else
        echo "DEBUG - OFF"
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