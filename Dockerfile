FROM alpine:3.17 AS builder

RUN apk add --no-cache \
        build-base \
        libmaxminddb-dev \
        ncurses-dev \
        musl-locales \   
        gettext-dev

# download goaccess
WORKDIR /goaccess-temp
<<<<<<< HEAD
COPY /assests/goaccess/goaccess-1.7.tar.gz goaccess.tar.gz
=======
COPY /assests/goaccess/goaccess-1.6.5.tar.gz goaccess.tar.gz
>>>>>>> main

# set up goacess-debug
WORKDIR /goaccess-debug
RUN cp /goaccess-temp/goaccess.tar.gz .
RUN tar --strip-components=1  -xzvf goaccess.tar.gz
RUN ./configure --enable-utf8 --enable-geoip=mmdb --with-getline --enable-debug
RUN make
RUN make install

# set up goacess
WORKDIR /goaccess
RUN cp /goaccess-temp/goaccess.tar.gz .
RUN tar --strip-components=1  -xzvf goaccess.tar.gz
RUN ./configure --enable-utf8 --enable-geoip=mmdb --with-getline
RUN make
RUN make install

FROM alpine:3.17
RUN apk add --no-cache \
        bash \
        nginx \
        tini \
        wget \
        curl \
        apache2-utils\
        libmaxminddb \
        tzdata \        
        gettext \
        musl-locales \
        ncurses && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/nginx/nginx.conf

COPY --from=builder /goaccess-debug /goaccess-debug
COPY --from=builder /goaccess /goaccess
COPY --from=builder /usr/local/share/locale /usr/local/share/locale

COPY /resources/goaccess/goaccess.conf /goaccess-config/goaccess.conf.bak
COPY /assests/maxmind/GeoLite2-City.mmdb /goaccess-config/GeoLite2-City.mmdb

# set up nginx
COPY /resources/nginx/nginx.conf /etc/nginx/nginx.conf
ADD /resources/nginx/.htpasswd /opt/auth/.htpasswd

# goaccess logs
WORKDIR /goaccess-logs

WORKDIR /goan
ADD /resources/scripts/funcs funcs
ADD /resources/scripts/logs logs
COPY /resources/scripts/start.sh start.sh
RUN chmod +x start.sh

VOLUME ["/opt/log"]
VOLUME ["/opt/custom"]
EXPOSE 7880
#CMD ["bash", "/goan/start.sh"]
ENTRYPOINT ["tini", "--", "/goan/start.sh"]