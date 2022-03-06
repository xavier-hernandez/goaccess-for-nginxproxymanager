FROM alpine:3.15 AS builder

RUN apk add --no-cache \
        build-base \
        libmaxminddb-dev \
        ncurses-dev \
        musl-libintl

# set up goacess
WORKDIR /goaccess
RUN wget https://tar.goaccess.io/goaccess-1.5.5.tar.gz
RUN tar --strip-components=1  -xzvf goaccess-1.5.5.tar.gz
RUN ./configure --enable-utf8 --enable-geoip=mmdb --with-getline
RUN make
RUN make install

FROM alpine:3.15
RUN apk add --no-cache \
        bash \
        nginx \
        tini \
        wget \
        curl \
        libmaxminddb \
        ncurses && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/nginx/nginx.conf

COPY --from=builder /goaccess /goaccess
COPY /resources/goaccess/goaccess.conf /goaccess-config/goaccess.conf
COPY /resources/goaccess/GeoLite2-City.mmdb /goaccess-config/GeoLite2-City.mmdb

# set up nginx
COPY /resources/nginx/index.html /var/www/html/index.html
COPY /resources/nginx/nginx.conf /etc/nginx/nginx.conf

COPY /resources/scripts/start.sh /start.sh
VOLUME ["/opt/log"]
EXPOSE 7880
CMD ["sh", "/start.sh"]