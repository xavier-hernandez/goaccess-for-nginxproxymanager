# GoAccess for Nginx Proxy Manager Logs

Still in development...

This docker container should work out of the box with Nginx Proxy Manager to parse proxy logs. The goaccess.conf has been configured to only access proxy logs and archived proxy logs.

The docker image scans and includes files matching the following criteria: proxy-host-_access.log.gz proxy-host-*_access.log

GoAccess version: 1.5.5

Thanks to https://github.com/GregYankovoy for the inspiration, and for their nginx.conf :)