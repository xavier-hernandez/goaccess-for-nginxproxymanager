#!/bin/bash

#BEGIN - Load archived logs
if [[ "${SKIP_ARCHIVED_LOGS}" == "True" ]]
then
    echo "Skipping archived logs as requested..."
    touch /goaccess/access_archive.log
else
    count=`ls -1 /opt/log/proxy-host-*_access.log*.gz 2>/dev/null | wc -l`
    if [ $count != 0 ]
    then 
        echo "Loading (${count}) archived logs..."
zcat -f /opt/log/proxy-host-*_access.log*.gz > /goaccess/access_archive.log
    else
        echo "No archived logs found..."
        touch /goaccess/access_archive.log
fi
fi
#END - Load archived logs

#BEGIN - Find active logs and check for read access
proxy_host=""

echo "Checking active logs..."
IFS=$'\n'
for file in $(find /opt/log -name 'proxy-host-*_access.log');
do
    if [ -f $file ]
    then
        if [ -r $file ] && R="Read = yes" || R="Read = No"
        then
            if [ -z "$proxy_host" ]
            then
                proxy_host="${proxy_host}${file}"
            else
                proxy_host="${proxy_host} ${file}"
            fi
            echo "Filename: $file | $R"
        else
            echo "Filename: $file | $R"
        fi
    else
        echo "Filename: $file | Not a file"
    fi
done
unset IFS

if [ -z "$proxy_host" ]
then
    touch /goaccess/access.log
    proxy_host="/goaccess/access.log"
else
    echo "Loading proxy-host logs..."    
fi
#END - Find active logs and check for read access

#RUN NGINX
tini -s -- nginx

#RUN GOACCESS
tini -s -- /goaccess/goaccess /goaccess/access_archive.log ${proxy_host} --no-global-config --config-file=/goaccess-config/goaccess.conf