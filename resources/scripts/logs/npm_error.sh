#!/bin/bash
function npm_error_init(){
    goan_config="/goaccess-config/error/goaccess.conf"
    nginx_html="/var/www/html/error/index.html"
    html_config="/var/www/html/error/goaccess_conf.html"
    archive_log="/goaccess-config/error/archive.log"
    active_log="/goaccess-config/error/active.log"

    if [[ -f ${goan_config} ]]; then
        rm ${goan_config}
    else
        mkdir -p "/goaccess-config/error/"
        cp /goaccess-config/goaccess.conf.bak ${goan_config}
    fi
    if [[ -f ${nginx_html} ]]; then
        rm ${nginx_html}
    else
        mkdir -p "/var/www/html/error/"
        touch ${nginx_html}
    fi
    if [[ -f ${html_config} ]]; then
        rm ${html_config}
    fi

    echo -n "" > ${archive_log}
    echo -n "" > ${active_log}
}

function npm_error_goaccess_config(){
    echo -e "\n\n\n" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "# ${goan_version}" >> ${goan_config}
    echo "# GOAN_NPM_ERROR_CONFIG" >> ${goan_config}
    echo "######################################" >> ${goan_config}
    echo "time-format %T" >> ${goan_config}
    echo "date-format %Y/%m/%d" >> ${goan_config}
    echo "log_format %d %t %^: %v, %^: %h, %^ %v %^"%r" %^" >> ${goan_config}
    echo "port 7892" >> ${goan_config}
    echo "real-time-html true" >> ${goan_config}
    echo "output ${nginx_html}" >> ${goan_config}
    if [[ "${ENABLE_BROWSERS_LIST}" == "True" || ${ENABLE_BROWSERS_LIST} == true ]]; then
        echo -e "\n\tENABLING NPM ERROR INSTANCE GOACCESS BROWSERS LIST"
        browsers_file="/goaccess-config/browsers.list"
        echo "browsers-file ${browsers_file}" >> ${goan_config}
    fi
}

function npm_error(){
    npm_error_init
    npm_error_goaccess_config

    echo -e "\nLOADING ERROR LOGS"
    echo "-------------------------------"

    echo $'\n' >> ${goan_config}
    echo "#GOAN_ERROR_LOG_FILES" >> ${goan_config}
    echo "log-file ${archive_log}" >> ${goan_config}
    echo "log-file ${active_log}" >> ${goan_config}

    goan_log_count=0
    goan_archive_log_count=0

    echo -e "\n#GOAN_NPM_ERROR_FILES" >> ${goan_config}
    if [[ -d "${goan_log_path}" ]]; then

        echo -e "\n\tAdding error logs..."
        IFS=$'\n'
        for file in $(find "${goan_log_path}" -name '*_error.log');
        do
            if [ -f $file ]
            then
                if [ -r $file ] && R="Read = yes" || R="Read = No"
                then
                    number_of_lines=`wc -l < $file`
                    how_many_lines_contain_warn=`grep -c "\[warn\]" $file`

                    if [ $how_many_lines_contain_warn == $number_of_lines ] && [ $number_of_lines != 0 ]
                    then
                        echo -e "\t${file} has inconsistent log types, skipping"
                    else
                        echo "log-file ${file}" >> ${goan_config}
                        goan_log_count=$((goan_log_count+1))
                        echo -ne ' \t '
                        echo "Filename: $file | $R"
                    fi
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

        echo -e "\tFound (${goan_log_count}) error logs..."

        echo -e "\n\tSKIP ARCHIVED LOGS"
        echo -e "\t-------------------------------"
        if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
        then
            echo -e "\tTRUE"
        else
            echo -e "\tFALSE"
            goan_archive_log_count=`ls -1 ${goan_log_path}/*_error.log*.gz 2> /dev/null | wc -l`

            if [ $goan_archive_log_count != 0 ]
            then
                echo -e "\n\tAdding error archive logs..."

                IFS=$'\n'
                for file in $(find "${goan_log_path}" -name '*_error.log*.gz');
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

                echo -e "\tAdded (${goan_archive_log_count}) error archived logs from ${goan_log_path}..."
                zcat -f ${goan_log_path}/*_error.log*.gz > ${archive_log}
                sed -e '/\[warn\]/d' -i ${archive_log}
            else
                echo -e "\tNo error archived logs found at ${goan_log_path}..."
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

    echo -e "\nRUN NPM ERROR GOACCESS"
    if [[ "${DEBUG}" == "True" ]]; then
        /goaccess-debug/goaccess --debug-file=${goaccess_debug_file} --invalid-requests=${goaccess_invalid_file} --no-global-config --config-file=${goan_config} &
    else
        /goaccess/goaccess --no-global-config --config-file=${goan_config} &
    fi
}
