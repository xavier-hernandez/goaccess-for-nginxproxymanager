#!/bin/bash
/usr/bin/tini -s -- nginx

#load archived logs
zcat -f /opt/log/proxy-host-*_access.log*.gz > /goaccess/access_archive.log

#find active logs
proxy_host=$(find /opt/log -name "proxy-host-*_access.log")

/usr/bin/tini -s -- /goaccess/goaccess /goaccess/access_archive.log ${proxy_host} --no-global-config --config-file=/goaccess-config/goaccess.conf