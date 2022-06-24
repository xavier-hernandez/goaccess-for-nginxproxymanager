#!/bin/bash

function set_npm_proxy_config() {
    echo -e "\n\n\n" >> ${1}
    echo "######################################" >> ${1}
    echo "# ${goan_version}" >> ${1}
    echo "# GOAN_PROXY_CONFIG" >> ${1}
    echo "######################################" >> ${1}
    echo "time-format %T" >> ${1}
    echo "date-format %d/%b/%Y" >> ${1}
    echo "log_format [%d:%t %^] %^ %^ %s - %m %^ %v \"%U\" [Client %h] [Length %b] [Gzip %^] [Sent-to %^] \"%u\" \"%R\"" >> ${1}
    echo "real-time-html true" >> ${1}
    echo "output /var/www/html/index.html" >> ${1}
<<<<<<< HEAD
}

function set_npm_redirection_config() {
    echo -e "\n\n\n" >> ${1}
    echo "######################################" >> ${1}
    echo "# ${goan_version}" >> ${1}
    echo "# GOAN_PROXY_CONFIG" >> ${1}
    echo "######################################" >> ${1}
    echo "time-format %T" >> ${1}
    echo "date-format %d/%b/%Y" >> ${1}
    echo "log_format [%d:%t %^] %s - %m %^ %v \"%U\" [Client %h] [Length %b] [Gzip %^] \"%u\" \"%R\"" >> ${1}
    echo "real-time-html true" >> ${1}
    echo "output /var/www/html/index.html" >> ${1}
=======
>>>>>>> v1.1.0
}

function set_traefik_config() {
    echo -e "\n\n\n" >> ${1}
    echo "######################################" >> ${1}
    echo "# ${goan_version}" >> ${1}
    echo "# GOAN_PROXY_CONFIG" >> ${1}
    echo "######################################" >> ${1}
    echo "time-format %T" >> ${1}
    echo "date-format %d/%b/%Y" >> ${1}
    echo "log-format %h %^[%d:%t %^] \"%r\" %s %b \"%R\" \"%u\" %Lm" >> ${1}
    echo "real-time-html true" >> ${1}
    echo "output /var/www/html/index.html" >> ${1}
<<<<<<< HEAD
    echo "hi"
=======
>>>>>>> v1.1.0
}

function set_geoip_database() {
    echo "geoip-database /goaccess-config/GeoLite2-City.mmdb" >> ${1}
}