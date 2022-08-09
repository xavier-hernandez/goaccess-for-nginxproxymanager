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
    if [[ -f "$archive_log" ]]; then
        rm ${archive_log}
    else
        touch ${archive_log}
    fi
    if [[ -f "$active_log" ]]; then
        rm ${active_log}
    else
        touch ${active_log}
    fi
}


function npm_redirect_goaccess_config(){
    echo -e "\n\n\n" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "# ${goan_version}" >> ${goan_config}
    echo "# GOAN_NPM_REDIRECTION_CONFIG" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "time-format %T" >> ${goan_config}
    echo "date-format %d/%b/%Y" >> ${goan_config}
    echo "log_format [%d:%t %^] %s - %m %^ %v \"%U\" [Client %h] [Length %b] [Gzip %^] \"%u\" \"%R\"" >> ${goan_config}
    echo "port 7891" >> ${goan_config}
    echo "real-time-html true" >> ${goan_config}
    echo "output ${nginx_html}" >> ${goan_config}
}

function npm_redirect(){
    npm_redirect_init
    npm_redirect_goaccess_config

    echo -e "\nLOADING REDIRECTION LOGS"
    echo "-------------------------------"

    echo $'\n' >> ${goan_config}
    echo "#GOAN_REDIRECTION_LOG_FILES" >> ${goan_config}
    echo "log-file ${archive_log}" >> ${goan_config}
    echo "log-file ${active_log}" >> ${goan_config}

    goan_log_count=0
    goan_archive_log_count=0

    echo -e "\n#GOAN_NPM_REDIRECT_FILES" >> ${goan_config}
    if [[ -d "${goan_log_path}" && -x "${goan_log_path}" ]]; then
        
        echo -e "\n\tAdding redirection logs..."
        IFS=$'\n'
        for file in $(find "${goan_log_path}" -name 'redirection*host-*.log' ! -name "*_error.log");
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

        echo -e "\tFound (${goan_log_count}) redirection logs..."

        echo -e "\n\tSKIP ARCHIVED LOGS"
        echo -e "\t-------------------------------"
        if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
        then
            echo -e "\tTRUE"
        else
            echo -e "\tFALSE"
            goan_archive_log_count=`ls -1 ${goan_log_path}/redirection*host-*.log*.gz 2> /dev/null | wc -l`

            if [ $goan_archive_log_count != 0 ]
            then 
                echo -e "\n\tAdding redirection archive logs..."

                IFS=$'\n'
                for file in $(find "${goan_log_path}" -name 'redirection*host-*.log*.gz' ! -name "*_error.log");
                do
                    if [ -f $file ]
                    then
                        if [ -r $file ] && R="Read = yes" || R="Read = No"
                        then
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

                echo -e "\tAdded (${goan_archive_log_count}) redirection archived logs from ${goan_log_path}..."
                zcat -f ${goan_log_path}/redirection*host-*.log*.gz > ${archive_log}
            else
                echo -e "\tNo redirection archived logs found at ${goan_log_path}..."
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

    echo -e "\nRUN NPM REDIRECT GOACCESS"
    if [[ "${DEBUG}" == "True" ]]; then
        /goaccess-debug/goaccess --debug-file=${goaccess_debug_file} --invalid-requests=${goaccess_invalid_file} --no-global-config --config-file=${goan_config} &
    else
        /goaccess/goaccess --no-global-config --config-file=${goan_config} &
    fi
}
