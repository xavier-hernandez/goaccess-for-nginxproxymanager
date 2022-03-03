#!/bin/bash
tini -s -- nginx

#load archived logs
zcat -f /opt/log/proxy-host-*_access.log*.gz > /goaccess/access_archive.log

#find active logs
proxy_host=""

echo "Checking active logs..."
IFS=$'\n'
for file in $(find /opt/log -name 'proxy-host-*_access.log');
do
    if [ -f $file ]
    then
        if [ -r $file ] && R="Read = yes" || R="Read = No"
        then
            proxy_host+=" $file"
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
fi
tini -s -- /goaccess/goaccess /goaccess/access_archive.log ${proxy_host} --no-global-config --config-file=/goaccess-config/goaccess.conf
