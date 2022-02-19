FROM ubuntu:20.04

RUN export DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y 

# install nginx
RUN apt-get install -y nginx

# install deps
RUN apt-get install -y build-essential libmaxminddb-dev libncurses-dev
RUN apt-get install -y tini ca-certificates wget curl 

# clean up
RUN apt-get autoremove -qy

# set up goacess
WORKDIR /goaccess
RUN wget https://tar.goaccess.io/goaccess-1.5.5.tar.gz
RUN tar --strip-components=1  -xzvf goaccess-1.5.5.tar.gz
RUN ./configure --enable-utf8 --enable-geoip=mmdb --with-getline
RUN make
RUN make install
COPY /resources/goaccess/goaccess.conf /goaccess-config/goaccess.conf

# set up nginx
RUN rm /etc/nginx/sites-enabled/default
COPY /resources/nginx/index.html /var/www/html/index.html
COPY /resources/nginx/nginx.conf /etc/nginx/nginx.conf

VOLUME ["/opt/log"]
EXPOSE 7880

COPY /resources/scripts/start.sh /start.sh
RUN ["chmod", "+x", "/start.sh"]
CMD ["bash", "/start.sh"]
