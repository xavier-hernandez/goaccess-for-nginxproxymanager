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

#Find active logs and check for read access
function logs_load_archive() {
    touch ${goan_container_archive_log}

    if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
    then
        echo "Skipping archived logs as requested..."
    else
        if [[ -d "${1}" && -x "${1}" ]];
        then
            count=`ls -1 ${1}/proxy-host-*_access.log*.gz | wc -l`
            if [ $count != 0 ]
            then 
                echo "Loading (${count}) archived logs from ${1}..."
                zcat -f ${1}/proxy-host-*_access.log*.gz > ${goan_container_archive_log}
                echo  "log-file ${goan_container_archive_log}" >> ${goan_container_proxy_logs}
            else
                echo "No archived logs found at ${1}..."
            fi
            goan_proxy_archive_log_count=$((count))
        else
            echo "Problem loading directory (check directory or permissions)... ${1}"
        fi
    fi
}