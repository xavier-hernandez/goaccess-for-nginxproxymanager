#!/bin/bash
function custom_init(){
    goan_config="/opt/custom/goaccess.conf"
    nginx_html="/var/www/html/index.html"
    html_config="/var/www/html/goaccess_conf.html"

    echo -e "\nCUSTOM"
    echo "-------------------------------"
    if [[ -f ${nginx_html} ]]; then
        rm ${nginx_html}
    else
        mkdir -p "/var/www/html/"
        touch ${nginx_html}
    fi
    if [[ -f ${html_config} ]]; then
        rm ${html_config}
    fi

    if [[ -f ${goan_config} ]]; then
        echo -e "goaccess.conf file found"
        if [[ "${DEBUG}" == "True" ]]; then
            echo -e "\n**************BEGIN DEBUG***********************"
            echo -e "${goan_config} file permissions"
            stat -L -c "%a %G %U" ${goan_config}
            echo -e "\n"
            echo -e "${goan_config} content"
            cat ${goan_config}
            echo -e "**************END DEBUG***********************\n"
        fi
        if [[ -r ${goan_config} ]]; then
            echo -e "goaccess.conf readable"
            if [[ "${ENABLE_BROWSERS_LIST}" == "True" || ${ENABLE_BROWSERS_LIST} == true ]]; then
                if grep -Fwq "browsers-file" ${goan_config}; then
                    echo -e "\n\t\BROWSERS FILE ALREADY DEFINED IN CUSTOM GOACCESS.CONF. IGNORING CUSTOM_BROWSERS VARIABLE"
                else
                    echo -e "\n\tENABLING CUSTOM INSTANCE GOACCESS BROWSERS LIST"
                    browsers_file="/goaccess-config/browsers.list"
                    echo "browsers-file ${browsers_file}" >> ${goan_config}
                fi
            fi
        else
            echo -e "goaccess.conf not readable"
            #exit
        fi
    else
        echo -e "goaccess.conf not found"
        exit
    fi
}

function custom(){
    custom_init

    #additonal config settings
    debug ${goan_config} ${html_config}

    #write out loading page
    echo "<!doctype html><html><head>" > ${nginx_html}
    echo "<title>GOAN - ${goan_version}</title>" >> ${nginx_html}
    echo "<meta http-equiv=\"refresh\" content=\"1\" >" >> ${nginx_html}
    echo "<style>body {font-family: Arial, sans-serif;}</style>" >> ${nginx_html}
    echo "</head><body><p><b>${goan_version}</b><br/><br/>loading... <br/><br/>" >> ${nginx_html}
    echo "Custom instance processing: (might take some time depending on the number of files to parse)" >> ${nginx_html}
    echo "<br/></p></body></html>" >> ${nginx_html}

    echo -e "\nRUN CUSTOM GOACCESS"
    if [[ "${DEBUG}" == "True" ]]; then
        /goaccess-debug/goaccess --debug-file=${goaccess_debug_file} --invalid-requests=${goaccess_invalid_file} --no-global-config --config-file=${goan_config} \
          --html-refresh="${HTML_REFRESH}" --keep-last="${KEEP_LAST}" "${GOACCESS_OTHER_OPTIONS" &
    else
        /goaccess/goaccess --no-global-config --config-file=${goan_config} \
          --html-refresh="${HTML_REFRESH}" --keep-last="${KEEP_LAST}" "${GOACCESS_OTHER_OPTIONS" &
    fi

}
