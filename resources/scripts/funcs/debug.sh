#ADD DEBUGGING

function debug() {
    if [[ "${DEBUG}" == "True" ]]
    then
        echo "DEBUG - ON"
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