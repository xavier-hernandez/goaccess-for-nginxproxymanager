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

#Find active logs and check for read access
function load_proxy_logs() {
    echo -e "\nLOADING ACTIVE PROXY LOGS"
    echo "-------------------------------"

    goan_proxy_log_count=0
    goan_proxy_archive_log_count=0

    echo -e "\n#GOAN_PROXY_FILES" >> ${2}
    if [[ -d "${1}" && -x "${1}" ]];
    then
        IFS=$'\n'
        for file in $(find "${1}" -name 'proxy*host-*.log' ! -name "*_error.log");
        do
            if [ -f $file ]
            then
                if [ -r $file ] && R="Read = yes" || R="Read = No"
                then
                    echo "log-file ${file}" >> ${2}
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
        echo "Problem loading directory (check directory or permissions)... ${1}"
    fi

    if [ $goan_proxy_log_count != 0 ]
    then
        echo "Found (${goan_proxy_log_count}) proxy logs..."
    fi

    echo -e "\nSKIP ARCHIVED LOGS"
    echo "-------------------------------"

    echo -e "\n#GOAN_ARCHIVE_PROXY_FILES" >> ${2}
    if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
    then
        echo "True"
    else
        echo "False"
        if [[ -d "${1}" && -x "${1}" ]];
        then
            count=`ls -1 ${1}/proxy-host-*_access.log*.gz 2> /dev/null | wc -l`
            if [ $count != 0 ]
            then 
                echo "Loading (${count}) archived logs from ${1}..."
                zcat -f ${1}/proxy-host-*_access.log*.gz > ${3}
                echo  "log-file ${3}" >> ${2}
                goan_proxy_archive_log_count=${count}
            else
                echo "No archived logs found at ${1}..."
            fi
        else
            echo "Problem loading directory (check directory or permissions)... ${1}"
        fi
    fi
    
    echo "<!doctype html><html><head>" > ${4}
    echo "<title>GOAN - ${goan_version}</title>" >> ${4}
    echo "<meta http-equiv=\"refresh\" content=\"1\" >" >> ${4}
    echo "<style>body {font-family: Arial, sans-serif;}</style>" >> ${4}
    echo "</head><body><p><b>${goan_version}</b><br/><br/>loading... <br/><br/>" >> ${4}
    echo "Logs processing: $(($goan_proxy_log_count + $goan_proxy_archive_log_count)) (might take some time depending on the number of files to parse)" >> ${4}
    echo "<br/></p></body></html>" >> ${4}
}

function load_traefik_logs() {
    echo -e "\nLOADING TRAEFIK LOGS"
    echo "-------------------------------"

    goan_proxy_log_count=0

    echo -e "\n#GOAN_PROXY_FILES" >> ${2}
    if [[ -d "${1}" && -x "${1}" ]];
    then
        IFS=$'\n'
        for file in $(find "${1}" -name 'access.log');
        do
            if [ -f $file ]
            then
                if [ -r $file ] && R="Read = yes" || R="Read = No"
                then
                    echo "log-file ${file}" >> ${2}
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
        echo "Problem loading directory (check directory or permissions)... ${1}"
    fi

    if [ $goan_proxy_log_count != 0 ]
    then
        echo "Found (${goan_proxy_log_count}) proxy logs..."
    else
        echo "No access.log found. Creating an empty log file..."
        touch "${goan_log_path}/access.log"
    fi

    echo -e "\nSKIP ARCHIVED LOGS"
    echo "-------------------------------"
    echo "FEATURE NOT AVAILABLE FOR TRAEFIK"
    
    echo "<!doctype html><html><head>" > ${3}
    echo "<title>GOAN - ${goan_version}</title>" >> ${3}
    echo "<meta http-equiv=\"refresh\" content=\"1\" >" >> ${3}
    echo "<style>body {font-family: Arial, sans-serif;}</style>" >> ${3}
    echo "</head><body><p><b>${goan_version}</b><br/><br/>loading... <br/><br/>" >> ${3}
    echo "Logs processing: $(($goan_proxy_log_count)) (might take some time depending on the number of files to parse)" >> ${3}
    echo "<br/></p></body></html>" >> ${3}
}

#ADD REDIRECTION LOGS
function redirection_logs() {
    archive_log="/goaccess-config/redirection_archive.log"
    active_log="/goaccess-config/redirection_active.log"
    conf="/goaccess-config/goaccess-redirection.conf"

    #clean up
    if [[ -f "$archive_log" ]]; then
        rm ${archive_log}
    fi
    if [[ -f "$active_log" ]]; then
        rm ${active_log}
    fi

    #console info
    echo $'\n'
    echo "Redirection Logs"
    echo "----------------------------------------"

    SKIP_ARCHIVED_LOGS="False"

    #create the log file and add to the conf
    touch ${archive_log}
    touch ${active_log}
    echo $'\n' >> ${conf}
    echo "#GOAN_LOG_FILES" >> ${conf}
    echo "log-file ${archive_log}" >> ${conf}
    echo "log-file ${active_log}" >> ${conf}

    goan_active_count=0
    
    #check directory access
    if [[ -d "${1}" && -x "${1}" ]];
    then
        if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
        then
            echo "Skipping archived logs as requested..."
        else
            goan_archive_count=`ls -1 ${1}/redirection-host-*_access.log*.gz  2> /dev/null | wc -l`
        
            if [ $goan_archive_count != 0 ]
            then 
                echo "Adding redirection archive logs..."

                IFS=$'\n'
                for file in $(find "${1}" -name 'redirection-host-*_access.log*.gz' ! -name "*_error.log");
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

                echo "Added (${goan_archive_count}) redirection archived logs from ${1}..."
                zcat -f ${1}/redirection-host-*_access.log*.gz > ${archive_log}
            else
                echo "No archived logs found at ${1}..."
            fi
        fi

        IFS=$'\n'
        for file in $(find "${1}" -name 'redirection-host-*.log' ! -name "*_error.log");
        do
            if [ $goan_active_count == 0 ]; then
                echo "Adding redirection active logs..."
            fi
            if [ -f $file ]
            then
                if [ -r $file ] && R="Read = yes" || R="Read = No"
                then
                    echo "log-file ${file}" >> ${conf}
                    echo -ne ' \t '
                    echo "Filename: $file | $R"
                    goan_active_count=$((goan_active_count+1))
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
        echo "Problem loading directory (check directory or permissions)... ${1}"
    fi

    if [ $goan_active_count != 0 ]
    then
        echo "Added (${goan_active_count}) redirection active logs from ${1}..."
    fi
}