#!/bin/bash
function npm_redirect_init(){
    goan_config="/goaccess-config/redirection/goaccess.conf"
    nginx_html="/var/www/html/redirection/index.html"
    html_config="/var/www/html/redirection/goaccess_conf.html"
    archive_log="/goaccess-config/redirection/archive.log"
    active_log="/goaccess-config/redirection/active.log"

    if [[ -f ${goan_config} ]]; then
        rm ${goan_config}
    else
        mkdir -p "/goaccess-config/redirection/"
        cp /goaccess-config/goaccess.conf.bak ${goan_config}
    fi
    if [[ -f ${nginx_html} ]]; then
        rm ${nginx_html}
    else
        mkdir -p "/var/www/html/redirection/"
        touch ${nginx_html}
    fi
    if [[ -f ${html_config} ]]; then
        rm ${html_config}
    fi

    echo -n "" > ${archive_log}
    echo -n "" > ${active_log}
}

function npm_redirect_goaccess_config(){
    echo -e "\n\n\n" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "# ${goan_version}" >> ${goan_config}
    echo "# GOAN_NPM_REDIRECTION_FALLBACK_DEAD_CONFIG" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "time-format %T" >> ${goan_config}
    echo "date-format %d/%b/%Y" >> ${goan_config}
    echo "log_format [%d:%t %^] %s - %m %^ %v \"%U\" [Client %h] [Length %b] [Gzip %^] \"%u\" \"%R\"" >> ${goan_config}
    echo "port 7891" >> ${goan_config}
    echo "real-time-html true" >> ${goan_config}
    echo "output ${nginx_html}" >> ${goan_config}
    if [[ "${ENABLE_BROWSERS_LIST}" == "True" || ${ENABLE_BROWSERS_LIST} == true ]]; then
        echo -e "\n\tENABLING NPM REDIRECTION INSTANCE GOACCESS BROWSERS LIST"
        browsers_file="/goaccess-config/browsers.list"
        echo "browsers-file ${browsers_file}" >> ${goan_config}
    fi
}

function npm_redirect(){
    npm_redirect_init
    npm_redirect_goaccess_config

    echo -e "\nLOADING REDIRECTION/FALLBACK/DEAD LOGS"
    echo "---------------------------------------"

    echo $'\n' >> ${goan_config}
    echo "#GOAN_REDIRECTION_FALLBACK_DEAD_LOG_FILES" >> ${goan_config}
    echo "log-file ${archive_log}" >> ${goan_config}
    echo "log-file ${active_log}" >> ${goan_config}

    goan_log_count=0
    goan_archive_log_count=0

    echo -e "\n#GOAN_NPM_REDIRECT_FALLBACK_DEAD_FILES" >> ${goan_config}
    if [[ -d "${goan_log_path}" ]]; then

        echo -e "\n\tAdding redirection/fallback/dead logs..."
        IFS=$'\n'
        for file in $(find "${goan_log_path}" \( -name 'redirection*host-*.log' -o -name 'fallback_access.log' -o -name 'dead-host*.log' \) ! -name "*_error.log*");
        do
            checkFile "$file"
            if [ $? -eq 0 ]; then
                echo "log-file ${file}" >> ${goan_config}
                ((goan_log_count++))
            fi
        done
        unset IFS

        echo -e "\tFound (${goan_log_count}) redirection/fallback/dead logs..."

        echo -e "\n\tSKIP ARCHIVED LOGS"
        echo -e "\t-------------------------------"
        if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
        then
            echo -e "\tTRUE"
        else
            echo -e "\tFALSE"
            goan_archive_log_count=$(find "${goan_log_path}" -type f \( -name 'redirection*host-*.log*.gz' -o -name 'fallback_access.log*.gz' -o -name 'dead-host*.log*.gz' \) ! -name "*_error.log*" | wc -l)
            goan_archive_detail_log_count=0

            if [ $goan_archive_log_count != 0 ]
            then
                echo -e "\n\tAdding redirection/fallback/dead archive logs..."

                IFS=$'\n'
                for file in $(find "${goan_log_path}" \( -name 'redirection*host-*.log*.gz' -o -name 'fallback_access.log*.gz' -o -name 'dead-host*.log*.gz' \) ! -name "*_error.log*");
                do
                     checkFile "$file"
                    if [ $? -eq 0 ]; then
                        zcat -f ${file} >> ${archive_log}
                        ((goan_archive_detail_log_count++))
                    fi
                done
                unset IFS

                echo -e "\n\tAdded (${goan_archive_detail_log_count}) redirection/fallback/dead archived logs from ${goan_log_path}..."

            else
                echo -e "\tNo redirection/fallback archived logs found at ${goan_log_path}..."
            fi
        fi

    else
        echo "Problem loading directory (check directory or permissions)... ${goan_log_path}"
    fi

    #additonal config settings
    exclude_ips             ${goan_config}
    set_geoip_database      ${goan_config}
    debug                   ${goan_config} ${html_config}

    #write out loading page
    echo "<!doctype html><html><head>" > ${nginx_html}
    echo "<title>GOAN - ${goan_version}</title>" >> ${nginx_html}
    echo "<meta http-equiv=\"refresh\" content=\"1\" >" >> ${nginx_html}
    echo "<style>body {font-family: Arial, sans-serif;}</style>" >> ${nginx_html}
    echo "</head><body><p><b>${goan_version}</b><br/><br/>loading... <br/><br/>" >> ${nginx_html}
    echo "Logs processing: $(($goan_log_count + $goan_archive_log_count)) (might take some time depending on the number of files to parse)" >> ${nginx_html}
    echo "<br/></p></body></html>" >> ${nginx_html}

    echo -e "\nRUN NPM REDIRECT/FALLBACK GOACCESS"
    if [[ "${DEBUG}" == "True" ]]; then
        /goaccess-debug/goaccess --debug-file=${goaccess_debug_file} --invalid-requests=${goaccess_invalid_file} --no-global-config --config-file=${goan_config} &
    else
        /goaccess/goaccess --no-global-config --config-file=${goan_config} &
    fi
}
