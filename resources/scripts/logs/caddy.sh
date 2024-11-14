#!/bin/bash
function caddyV1_init(){
    goan_config="/goaccess-config/goaccess.conf"
    nginx_html="/var/www/html/index.html"
    html_config="/var/www/html/goaccess_conf.html"
    archive_log="/goaccess-config/archive.log"
    active_log="/goaccess-config/active.log"

    if [[ -f ${goan_config} ]]; then
        rm ${goan_config}
    else
        mkdir -p "/goaccess-config/"
        cp /goaccess-config/goaccess.conf.bak ${goan_config}
    fi
    if [[ -f ${nginx_html} ]]; then
        rm ${nginx_html}
    else
        mkdir -p "/var/www/html/"
        touch ${nginx_html}
    fi
    if [[ -f ${html_config} ]]; then
        rm ${html_config}
    fi

    echo -n "" > ${archive_log}
    echo -n "" > ${active_log}
}

function caddyV1_goaccess_config(){
    echo -e "\n\n\n" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "# ${goan_version}" >> ${goan_config}
    echo "# GOAN_PROXY_CONFIG" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "time-format ${TIME_FORMAT:-%s}" >> ${goan_config}
    echo "date-format ${DATE_FORMAT:-%s}" >> ${goan_config}
    echo "date-spec min" >> ${goan_config}
    echo "log-format CADDY" >> ${goan_config}
    echo "port 7890" >> ${goan_config}
    echo "real-time-html true" >> ${goan_config}
    echo "output ${nginx_html}" >> ${goan_config}
    if [[ "${ENABLE_BROWSERS_LIST}" == "True" || ${ENABLE_BROWSERS_LIST} == true ]]; then
        echo -e "\n\tENABLING CADDY INSTANCE GOACCESS BROWSERS LIST"
        browsers_file="/goaccess-config/browsers.list"
        echo "browsers-file ${browsers_file}" >> ${goan_config}
    fi
}

function caddyV1(){
    caddyV1_init
    caddyV1_goaccess_config

    echo -e "\nLOADING CADDY LOGS"
    echo "-------------------------------"

    echo $'\n' >> ${goan_config}
    echo "#GOAN_CADDY_LOG_FILES" >> ${goan_config}
    echo "log-file ${archive_log}" >> ${goan_config}
    echo "log-file ${active_log}" >> ${goan_config}

    goan_log_count=0
    goan_archive_log_count=0

    echo -e "\n#GOAN_PROXY_FILES" >> ${goan_config}
    if [[ -d "${goan_log_path}" ]]; then

        echo -e "\n\tAdding proxy logs..."
        IFS=$'\n'

        if [[ -z "${LOG_TYPE_FILE_PATTERN}" ]]; then
            LOG_TYPE_FILE_PATTERN="access.log"
        else
            LOG_TYPE_FILE_PATTERN="*.log"
        fi

        for file in $(find "${goan_log_path}" -name "${LOG_TYPE_FILE_PATTERN}");
        do
            if [ -f $file ]
            then
                if [ -r $file ] && R="Read = yes" || R="Read = No"
                then
                    echo "log-file ${file}" >> ${goan_config}
                    goan_log_count=$((goan_log_count+1))
                    echo -ne ' \t '
                    echo "Filename: $file | $R"
                else
                    echo -ne ' \t '
                    echo "Filename: $file | $R"
                fi
            else
                echo -ne ' \t '
                echo "Filename: $file | Not a file"
            fi
        done
        unset IFS
    else
        echo "Problem loading directory (check directory or permissions)... ${goan_log_path}"
    fi

    if [ $goan_log_count != 0 ]
    then
        echo "Found (${goan_log_count}) proxy logs..."
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
    echo "FEATURE NOT AVAILABLE FOR CADDY"

    #write out loading page
    echo "<!doctype html><html><head>" > ${nginx_html}
    echo "<title>GOAN - ${goan_version}</title>" >> ${nginx_html}
    echo "<meta http-equiv=\"refresh\" content=\"1\" >" >> ${nginx_html}
    echo "<style>body {font-family: Arial, sans-serif;}</style>" >> ${nginx_html}
    echo "</head><body><p><b>${goan_version}</b><br/><br/>loading... <br/><br/>" >> ${nginx_html}
    echo "Logs processing: $(($goan_log_count)) (might take some time depending on the number of files to parse)" >> ${nginx_html}
    echo "<br/></p></body></html>" >> ${nginx_html}

    echo -e "\nRUN CADDY GOACCESS"
    runGoAccess
}
