#!/bin/bash

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

#Set app image version
function nginx_image_version() {
    src="#goan_version"
    rpl=${goan_version}
    sed -i "s/$src/$rpl/" /var/www/html/index.html
}

function nginx_processing_count() {
    src="#goan_processing_count"
    rpl=$((goan_proxy_log_count+goan_proxy_archive_log_count))
    sed -i "s/$src/$rpl/" /var/www/html/index.html
}