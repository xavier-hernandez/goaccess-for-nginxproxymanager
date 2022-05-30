#!/bin/bash

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

function logs_load_active() {
    echo "Checking active logs..."
    if [[ -d "${1}" && -x "${1}" ]];
    then
        IFS=$'\n'
        for file in $(find "${1}" -name 'proxy*host-*.log' ! -name "*_error.log");
        do
            if [ -f $file ]
            then
                if [ -r $file ] && R="Read = yes" || R="Read = No"
                then
                    echo "log-file ${file}" >> ${goan_container_proxy_logs}
                        goan_proxy_log_count=$((goan_proxy_log_count+1))
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
        echo "Problem loading directory (check directory or permissions)... ${1}"
    fi

    if [ $goan_proxy_log_count != 0 ]
    then
        echo "Found (${goan_proxy_log_count}) proxy logs...."
    else
        touch ${goan_container_active_log}
        echo "log-file ${goan_container_active_log}" >> ${goan_container_proxy_logs}
    fi
}