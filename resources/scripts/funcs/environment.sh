#!/bin/bash

#Exclude IPs
function exclude_ips() {
    echo -e "\nEXCLUDE IPS"
    echo "-------------------------------"    
    if [[ -z "${EXCLUDE_IPS}" ]]
    then
        echo "None"
    else
        ips=""

        echo $'\n' >> ${1}
        echo "#GOAN_EXCLUDE_IPS" >> ${1}
        IFS=','
        read -ra ADDR <<< "$EXCLUDE_IPS"
        for ip in "${ADDR[@]}"; do
            echo ${ip}
            echo "exclude-ip ${ip}" >> ${1}
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
        echo "ON"
        echo "<!doctype html><html><head>" > ${2}
        echo "<title>GOAN - ${goan_version}</title>" >> ${2}
        echo "<style>body{font-family:Arial,sans-serif;}code{white-space:pre-wrap;}</style>" >> ${2}
        echo "</head><body><code>" >> ${2}
        cat ${1} >> ${2}
        echo "</code></body></html>" >> ${2}
    else
        echo -e "OFF"
    fi
}

function set_geoip_database() {
    echo -e "\nSetting GeoIP Database"
    echo "-------------------------------"
    echo "DEFAULT"
    
    echo $'\n' >> ${1}
    echo "#GOAN_MAXMIND_DB" >> ${1}
    echo "geoip-database /goaccess-config/GeoLite2-City.mmdb" >> ${1}
}