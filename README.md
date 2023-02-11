# GoAccess for Nginx Proxy Manager Logs
  
Still in development... You might need to wait a bit if you have a large amount of logs for it to parse.

**Parses the following log types:**
- NPM
- NPM Redirection
- NPM Error
- Traefik
- Load your own custom config as well to parse other logs
 
<br/>

![Alt text](https://i.ibb.co/fNj9Dcy/goaccess1.jpg "GoAccess Dashboard")

**Dependencies:**
- GoAccess version: 1.7
- GeoLite2-City.mmdb  (2023-02-10)
- GeoLite2-Country.mmdb  (2023-02-10)
- GeoLite2-ASN.mmdb  (2023-02-10)

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
version: '3.3'
services:
    goaccess:
        image: 'xavierh/goaccess-for-nginxproxymanager:latest'
        container_name: goaccess
        restart: always
        ports:
            - '7880:7880'
        environment:
            - TZ=America/New_York         
            - SKIP_ARCHIVED_LOGS=False #optional
            - DEBUG=False #optional
            - BASIC_AUTH=False #optional
            - BASIC_AUTH_USERNAME=user #optional
            - BASIC_AUTH_PASSWORD=pass #optional   
            - EXCLUDE_IPS=127.0.0.1 #optional - comma delimited 
            - LOG_TYPE=NPM #optional - more information below
        volumes:
        - /path/to/host/nginx/logs:/opt/log
        - /path/to/host/custom:/opt/custom #optional, required if using log_type = CUSTOM
```
If you have permission issues, you can add PUID and PGID with the correct user id that has read access to the log files.
```yml
version: '3.3'
services:
    goaccess:
        image: 'xavierh/goaccess-for-nginxproxymanager:latest'
        container_name: goaccess
        restart: always
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
            - EXCLUDE_IPS=127.0.0.1 #optional - comma delimited 
            - LOG_TYPE=NPM #optional - more information below
        volumes:
        - /path/to/host/nginx/logs:/opt/log
        - /path/to/host/custom:/opt/custom #optional, required if using log_type = CUSTOM
```

| Parameter | Function |
|-----------|----------|
| `-e SKIP_ARCHIVED_LOGS=True/False`         |   (Optional) Defaults to False. Set to True to skip archived logs, i.e. proxy-host*.gz     |
| `-e DEBUG=True/False`         |   (Optional) HTML version of the running goaccess.conf within the container     |
| `-e BASIC_AUTH=True/False`         |   (Optional) Defaults to False. Set to True to enable nginx basic authentication.  Docker container needs to stopped or restarted each time this flag is modified. This allows for the .htpasswd file to be changed accordingly.   |
| `-e BASIC_AUTH_USERNAME=user`         |   (Optional) Requires BASIC_AUTH to bet set to True.  Username for basic authentication.     |
| `-e BASIC_AUTH_PASSWORD=pass`         |   (Optional) Requires BASIC_AUTH to bet set to True.  Password for basic authentication.     |
| `-e EXCLUDE_IPS=`         |   (Optional) IP Addresses or range of IPs delimited by comma refer to https://goaccess.io/man. For example: 192.168.0.1-192.168.0.100 or 127.0.0.1,192.168.0.1-192.168.0.100   |
| `-e LOG_TYPE=`         |   (Optional) By default the configuration will be set to read NPM logs. Options are: CUSTOM, NPM, NPM+R, TRAEFIK, NCSA_COMBINED. More information below.|
| `-e LOG_TYPE_FILE_PATTERN=`         |   (Optional) Only to be used with LOG_TYPE=NCSA_COMBINED. This parameter will pass along the file type you are trying match. For example you can pass -e LOG_TYPE_FILE_PATTERN="*.log" or -e LOG_TYPE_FILE_PATTERN="access.log". The default is *.log. Please keep it simple as I have not tested this completely. Use at your own RISK! |
| `-e LANG=zh_CN.UTF-8 -e LANGUAGE=zh_CN.UTF-8`         |   (Optional) Language localization added. GoAccess only has a few translations available. Please visit https://github.com/allinurl/goaccess/tree/master/po to see the translations available. <br/><br/>**Current Translations**<br/>de - German<br/>es - Spanish<br/>fr - French<br/>it - Italian<br/>ja - Japanese<br/>ko - Korean<br/>pt_BR - Portuguese (Brazil)<br/>ru - Russian<br/>sv - Swedish<br/>uk - English (United Kingdom)<br/>zh_CN - Chinese - Simplified|


# **Additional environment information**  
` -e LOG_TYPE=`  
- Options:
  - CUSTOM
    - this feature will load your own configuration
    - an additional volume must be included
      - /path/to/host/custom:/opt/custom
    - volume should include
        - goaccess.conf
          - this is your custom config
          - container will exit if no file is found
          - leave the default port number at 7890
    - environment parameters that will not work and will be ignored
      - SKIP_ARCHIVED_LOGS
      - EXCLUDE_IPS
  - NPM (default if variable is empty or not included)
    - the following file(s) are read and parsed.
      - proxy-host-*_access.log.gz
      - proxy-host-*_access.log
      - proxy\*host-*.log
  - NPM+R
    - a second instance of GOACCESS is created
    - append "/redirection" to the url to access the instance, for example http://localhost:7880/redirection/
    - the following file(s) are read and parsed.
      - redirection\*host-*.log*.gz
      - redirection\*host-*.log
  - NPM+ALL
    - a second and third instance of GOACCESS are created
      - append "/redirection" to the url to access the instance, for example http://localhost:7880/redirection/
        - the following file(s) are read and parsed.
          - redirection\*host-*.log*.gz
          - redirection\*host-*.log
      - append "/error" to the url to access the instance, for example http://localhost:7880/error/
        - the following file(s) are read and parsed.
          - \*_error.log*.gz
          - \*_error.log
  - TRAEFIK
    - environment parameters that will not work and will be ignored
      - SKIP_ARCHIVED_LOGS
    - the following file(s) are read and parsed.
      - access.log
  - NCSA_COMBINED
    - environment parameters that will not work and will be ignored
      - SKIP_ARCHIVED_LOGS
    - by default the following file(s) are read and parsed.
      - *.log


# **LOG FORMATS**
### NPM PROXY LOG FORMAT
```
time-format %T
date-format %d/%b/%Y
log_format [%d:%t %^] %^ %^ %s - %m %^ %v "%U" [Client %h] [Length %b] [Gzip %^] [Sent-to %^] "%u" "%R"
```

### NPM REDIRECTION LOG FORMAT
```
time-format %T
date-format %d/%b/%Y
log_format [%d:%t %^] %s - %m %^ %v "%U" [Client %h] [Length %b] [Gzip %^] "%u" "%R"
```

### NPM ERROR LOG FORMAT
```
time-format %T
date-format %Y/%m/%d
log_format %d %t %^: %v, %^: %h, %^ %v %^"%r" %^
```

### TRAEFIK ACCESS LOG FORMAT
```
time-format %T
date-format %d/%b/%Y
log-format %h %^[%d:%t %^] "%r" %s %b "%R" "%u" %Lm"
```

# **Possible Issues** 
- A lot of CPU Usage and 10000 request every second in webUI
  - https://github.com/xavier-hernandez/goaccess-for-nginxproxymanager/issues/38
- If your using NPM to proxy the container you need to turn on websockets support
  - https://github.com/xavier-hernandez/goaccess-for-nginxproxymanager/issues/69

# **Thanks**
To https://github.com/GregYankovoy for the inspiration, and for their nginx.conf :)

Users:
- Just5KY
- martadinata666 

# **Disclaimer** 
This product includes GeoLite2 data created by MaxMind, available from
<a href="https://www.maxmind.com">https://www.maxmind.com</a>.
