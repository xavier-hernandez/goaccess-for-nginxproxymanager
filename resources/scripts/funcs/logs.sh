#!/bin/bash

#Find active logs and check for read access
function logs_load_active() {
    echo "Checking active logs..."
    if [[ -d "${1}" && -x "${1}" ]];
    then
        IFS=$'\n'
        for file in $(find "${1}" -name 'proxy-host-*.log' ! -name "*_error.log");
        do
            if [ -f $file ]
            then
                if [ -r $file ] && R="Read = yes" || R="Read = No"
                then
                    if [ -z "$goan_proxy_host" ]
                    then
                        goan_proxy_host="${goan_proxy_host}${file}"
                        goan_proxy_log_count=$((goan_proxy_log_count+1))
                    else
                        goan_proxy_host="${goan_proxy_host} ${file}"
                        goan_proxy_log_count=$((goan_proxy_log_count+1))
                    fi
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

    if [ -z "$goan_proxy_host" ]
    then
        touch ${goan_container_active_log}
        goan_proxy_host=${goan_container_active_log}
    else
        echo "Found (${goan_proxy_log_count}) proxy logs...."
    fi
}

#Find active logs and check for read access
function logs_load_archive() {
    if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
    then
        echo "Skipping archived logs as requested..."
        touch ${goan_container_archive_log}
    else
        if [[ -d "${1}" && -x "${1}" ]];
        then
            count=`ls -1 ${1}/proxy-host-*_access.log*.gz 2>/dev/null | wc -l`
            if [ $count != 0 ]
            then 
                echo "Loading (${count}) archived logs from ${1}..."
                zcat -f ${1}/proxy-host-*_access.log*.gz > ${goan_container_archive_log}
            else
                echo "No archived logs found at ${1}..."
                touch ${goan_container_archive_log}
            fi
            goan_proxy_archive_log_count=$((count))
        else
            echo "Problem loading directory (check directory or permissions)... ${1}"
        fi
    fi
}