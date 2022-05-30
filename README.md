# GoAccess for Nginx Proxy Manager Logs

Still in development... You might need to wait a bit if you have a large amount of logs for it to parse.

<br>

![Alt text](https://i.ibb.co/fNj9Dcy/goaccess1.jpg "GoAccess Dashboard")

New to creating docker images so bear with me. I did this more for me then for public consumption but it appears to work so maybe someone might find it useful.

This docker container should work out of the box with Nginx Proxy Manager to parse proxy logs. The goaccess.conf has been configured to only access proxy logs and archived proxy logs.

The docker image scans and includes files matching the following criteria: 
* proxy-host-*_access.log.gz
* proxy-host-*_access.log
* proxy-host-*.log
* proxy_host-*.log

**Dependencies:**
- GoAccess version: 1.5.5  
- GeoLite2-City.mmdb  (2022-04-26)

---

## **Docker**
- Image: https://hub.docker.com/r/xavierh/goaccess-for-nginxproxymanager
- OS/ARCH
  - linux/amd64
  - linux/arm/v7
  - linux/arm64/v8
- ARM also available from Just5KY - [justsky/goaccess-for-nginxproxymanager](https://hub.docker.com/r/justsky/goaccess-for-nginxproxymanager)
- Tags: https://hub.docker.com/r/xavierh/goaccess-for-nginxproxymanager/tags
  - stable - xavierh/goaccess-for-nginxproxymanager:latest
  - latest stable development - xavierh/goaccess-for-nginxproxymanager:develop


## **Github Repo**   
- https://github.com/xavier-hernandez/goaccess-for-nginxproxymanager

---


```yml
goaccess:
    image: xavierh/goaccess-for-nginxproxymanager:latest
    container_name: goaccess
    restart: always
    environment:
        - TZ=America/New_York
        - SKIP_ARCHIVED_LOGS=False #optional
        - DEBUG=False #optional
        - BASIC_AUTH=False #optional
        - BASIC_AUTH_USERNAME=user #optional
        - BASIC_AUTH_PASSWORD=pass #optional
        - EXCLUDE_IPS=127.0.0.1 #comma delimited list                
    ports:
        - '7880:7880'
    volumes:
        - /path/to/host/nginx/logs:/opt/log
```
If you have permission issues, you can add PUID and PGID with the correct user id that has read access to the log files.
```yml
goaccess:
    image: xavierh/goaccess-for-nginxproxymanager:latest
    container_name: goaccess
    restart: always
    volumes:
        - /path/to/host/nginx/logs:/opt/log
    ports:
        - '7880:7880'
    environment:
        - PUID=0
        - PGID=0
        - TZ=America/New_York        
        - SKIP_ARCHIVED_LOGS=False #optional
        - DEBUG=False #optional
        - BASIC_AUTH=False #optional
        - BASIC_AUTH_USERNAME=user #optional
        - BASIC_AUTH_PASSWORD=pass #optional   
        - EXCLUDE_IPS=127.0.0.1 #comma delimited 
```

| Parameter | Function |
|-----------|----------|
| `-e SKIP_ARCHIVED_LOGS=True/False`         |   (Optional) Defaults to False. Set to True to skip archived logs, i.e. proxy-host*.gz     |
| `-e DEBUG=True/False`         |   (Optional) HTML version of the running goaccess.conf wihtin the container     |
| `-e BASIC_AUTH=True/False`         |   (Optional) Defaults to False. Set to True to enable nginx basic authentication.  Docker container needs to stopped or restarted each time this flag is modified. This allows for the .htpasswd file to be changed accordingly.   |
| `-e BASIC_AUTH_USERNAME=user`         |   (Optional) Requires BASIC_AUTH to bet set to True.  Username for basic authentication.     |
| `-e BASIC_AUTH_PASSWORD=pass`         |   (Optional) Requires BASIC_AUTH to bet set to True.  Password for basic authentication.     |
| `-e EXCLUDE_IPS=`         |   (Optional) IP Addresses or range of IPs delimited by comma refer to https://goaccess.io/man. For example: 192.168.0.1-192.168.0.100 or 127.0.0.1,192.168.0.1-192.168.0.100   |

Thanks to https://github.com/GregYankovoy for the inspiration, and for their nginx.conf :)

This product includes GeoLite2 data created by MaxMind, available from
<a href="https://www.maxmind.com">https://www.maxmind.com</a>.