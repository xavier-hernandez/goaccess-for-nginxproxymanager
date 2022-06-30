#!/bin/bash
function traefik_init(){
    goan_config="/goaccess-config/goaccess.conf"
    nginx_html="/var/www/html/index.html"
    html_config="/var/www/html/goaccess_conf.html"
    archive_log="/goaccess-config/access_archive.log"
    active_log="/goaccess-config/active.log"
}

function traefik_instance(){
    traefik_init

    echo 'Starting redirection log instance'
    tini -s -- /goaccess/goaccess --daemonize --no-global-config --config-file={goan_config}
}
function traefik_cleanup(){
    #clean up
    if [[ -f ${html_config} ]]; then
        rm ${html_config}
    fi
    if [[ -f ${nginx_html} ]]; then
        rm ${nginx_html}
    fi
    if [[ -f "$archive_log" ]]; then
        rm ${archive_log}
    fi
    if [[ -f "$archive_log" ]]; then
        rm ${archive_log}
    fi
    cp /goaccess-config/goaccess.conf.bak ${goan_config}
    #end of clean up
}

function traefik_goaccess_config(){
    echo -e "\n\n\n" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "# ${goan_version}" >> ${goan_config}
    echo "# GOAN_PROXY_CONFIG" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "time-format %T" >> ${1}
    echo "date-format %d/%b/%Y" >> ${goan_config}
    echo "log-format %h %^[%d:%t %^] \"%r\" %s %b \"%R\" \"%u\" %Lm" >> ${goan_config}
    echo "real-time-html true" >> ${goan_config}
    echo "output /var/www/html/index.html" >> ${goan_config}
}

function traefik(){
    traefik_init
    traefik_cleanup
    traefik_goaccess_config

    echo -e "\nLOADING TRAEFIK LOGS"
    echo "-------------------------------"

    goan_proxy_log_count=0

    echo -e "\n#GOAN_PROXY_FILES" >> ${goan_config}
    if [[ -d "${goan_log_path}" && -x "${goan_log_path}" ]];
    then
        IFS=$'\n'
        for file in $(find "${goan_log_path}" -name 'access.log');
        do
            if [ -f $file ]
            then
                if [ -r $file ] && R="Read = yes" || R="Read = No"
                then
                    echo "log-file ${file}" >> ${goan_config}
                    goan_proxy_log_count=$((goan_proxy_log_count+1))
                    echo "Filename: $file | $R"
                else
                    echo "Filename: $file | $R"
                fi
            else
                echo "Filename: $file | Not a file"
            fi
        done
        unset IFS
    else
        echo "Problem loading directory (check directory or permissions)... ${goan_log_path}"
    fi

    if [ $goan_proxy_log_count != 0 ]
    then
        echo "Found (${goan_proxy_log_count}) proxy logs..."
    else
        echo "No access.log found. Creating an empty log file..."
        touch "${goan_log_path}/access.log"
    fi

    #additonal config settings
    exclude_ips             ${goan_config}
    debug                   ${goan_config} ${html_config}
    set_geoip_database      ${goan_config}

    echo -e "\nSKIP ARCHIVED LOGS"
    echo "-------------------------------"
    echo "FEATURE NOT AVAILABLE FOR TRAEFIK"
    
    #write out loading page
    echo "<!doctype html><html><head>" > ${nginx_html}
    echo "<title>GOAN - ${goan_version}</title>" >> ${nginx_html}
    echo "<meta http-equiv=\"refresh\" content=\"1\" >" >> ${nginx_html}
    echo "<style>body {font-family: Arial, sans-serif;}</style>" >> ${nginx_html}
    echo "</head><body><p><b>${goan_version}</b><br/><br/>loading... <br/><br/>" >> ${nginx_html}
    echo "Logs processing: $(($goan_proxy_log_count)) (might take some time depending on the number of files to parse)" >> ${nginx_html}
    echo "<br/></p></body></html>" >> ${nginx_html}
}