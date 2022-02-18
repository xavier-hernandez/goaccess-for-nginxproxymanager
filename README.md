# GoAccess for Nginx Proxy Manager Logs

Still in development... You might need to wait a bit if you have a large amount of logs for it parse.

Docker image: https://hub.docker.com/r/xavierh/goaccess-for-nginxproxymanager

Github Repo: https://github.com/xavier-hernandez/goaccess-for-nginxproxymanager

![Alt text](https://i.ibb.co/fNj9Dcy/goaccess1.jpg "GoAccess Dashboard")

New to creating docker images so bear with me. I did this more for me then for public consumption but it appears to work so maybe someone might find it useful.

This docker container should work out of the box with Nginx Proxy Manager to parse proxy logs. The goaccess.conf has been configured to only access proxy logs and archived proxy logs.

The docker image scans and includes files matching the following criteria: proxy-host-_access.log.gz proxy-host-*_access.log

GoAccess version: 1.5.5

```
goaccess:
    image: xavierh/goaccess-for-nginxproxymanager:develop
    container_name: goaccess
    restart: always
    environment:
        - TZ=America/New_York
    ports:
        - '7880:7880'
    volumes:
        - ./nginx_proxy/data/logs:/opt/log
```

Issues currently aware of:
- Need a default index.html page, you need to currently wait for something to parse to see the website if your logs are too big (maybe healthcheck)
- An option to not load archived logs
- GeoIP database needs to be loaded
- New proxy host will not automatically show up, image needs to be restarted
- Allow for goaccess.conf access
- and more that I don't know of I'm sure...


Thanks to https://github.com/GregYankovoy for the inspiration, and for their nginx.conf :)