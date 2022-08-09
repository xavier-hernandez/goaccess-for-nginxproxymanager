FROM alpine:3.16.0 AS builder

RUN apk add --no-cache \
        build-base \
        libmaxminddb-dev \
        ncurses-dev \
        musl-libintl

# download goaccess
WORKDIR /goaccess-temp
RUN wget https://tar.goaccess.io/goaccess-1.6.2.tar.gz

# set up goacess-debug
WORKDIR /goaccess-debug
RUN cp /goaccess-temp/goaccess-1.6.2.tar.gz .
RUN tar --strip-components=1  -xzvf goaccess-1.6.2.tar.gz
RUN ./configure --enable-utf8 --enable-geoip=mmdb --with-getline --enable-debug
RUN make
RUN make install

# set up goacess
WORKDIR /goaccess
RUN cp /goaccess-temp/goaccess-1.6.2.tar.gz .
RUN tar --strip-components=1  -xzvf goaccess-1.6.2.tar.gz
RUN ./configure --enable-utf8 --enable-geoip=mmdb --with-getline
RUN make
RUN make install

FROM alpine:3.16.0
RUN apk add --no-cache \
        bash \
        nginx \
        tini \
        wget \
        curl \
        apache2-utils\
        libmaxminddb \
        tzdata \        
        ncurses && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/nginx/nginx.conf

COPY --from=builder /goaccess-debug /goaccess-debug
COPY --from=builder /goaccess /goaccess

COPY /resources/goaccess/goaccess.conf /goaccess-config/goaccess.conf.bak
COPY /resources/goaccess/GeoLite2-City.mmdb /goaccess-config/GeoLite2-City.mmdb

# set up nginx
COPY /resources/nginx/nginx.conf /etc/nginx/nginx.conf
ADD /resources/nginx/.htpasswd /opt/auth/.htpasswd

# goaccess logs
WORKDIR /goaccess-logs

WORKDIR /goan
ADD /resources/scripts/funcs funcs
ADD /resources/scripts/logs logs
COPY /resources/scripts/start.sh start.sh

VOLUME ["/opt/log"]
VOLUME ["/opt/custom"]
EXPOSE 7880
#CMD ["bash", "/goan/start.sh"]
ENTRYPOINT ["tini", "--", "/goan/start.sh"]