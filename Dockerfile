FROM alpine:3.18 AS builder

RUN apk add --no-cache \
        build-base \
        libmaxminddb-dev \
        ncurses-dev \
        musl-locales \   
        gettext-dev

# download goaccess
WORKDIR /goaccess-temp
COPY /assests/goaccess/goaccess-1.7.2.tar.gz goaccess.tar.gz

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
RUN sed -i "s/GWSocket<\/a>/GWSocket<\/a> ( <a href='https:\/\/tiny.one\/xgoan'>GOAN<\/a> <span>v1.1.21<\/span> )/" /goaccess/resources/tpls.html
RUN sed -i "s/bottom: 190px/bottom: 260px/" /goaccess/resources/css/app.css
RUN ./configure --enable-utf8 --enable-geoip=mmdb --with-getline
RUN make
RUN make install

FROM alpine:3.18
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
COPY /assests/maxmind/GeoLite2-ASN.mmdb /goaccess-config/GeoLite2-ASN.mmdb
COPY /assests/maxmind/GeoLite2-Country.mmdb /goaccess-config/GeoLite2-Country.mmdb

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

# store archives
RUN mkdir -p /goaccess-logs/archives

VOLUME ["/opt/log"]
VOLUME ["/opt/custom"]
EXPOSE 7880
#CMD ["bash", "/goan/start.sh"]
ENTRYPOINT ["tini", "--", "/goan/start.sh"]