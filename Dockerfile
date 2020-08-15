FROM csigabit/baseimage-alpine:3.12

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DOMOTICZ_COMMIT
LABEL build_version="Custom version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="csigabit"

# environment settings
ENV HOME="/config"

RUN \
 echo "nameserver 1.1.1.1" > /etc/resolv.conf && \
 echo "**** install build packages ****" && \
 rm -rf /var/cache/apk/* && \
 apk update && \
 apk add --no-cache --virtual=build-dependencies \
	argp-standalone \
	autoconf \
	automake \
	binutils \
	boost-dev \
	confuse-dev \
	curl-dev \
	dpkg \
	eudev-dev \
	g++ \
	gcc \
	git \
	gzip \
	jq \
	libcurl \
	libftdi1-dev \
	libressl-dev \
	libusb-compat-dev \
	libusb-dev \
	linux-headers \
	make \
	mosquitto-dev \
	musl-dev \
	pkgconf \
	sqlite-dev \
	tar \
	zlib-dev && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	boost \
	boost-system \
	boost-thread \
	curl \
	eudev-libs \
	iputils \
	openssl \
	lua5.3-dev \
	python3-dev && \
 wget http://ftp.hu.debian.org/debian/pool/main/libc/libcereal/libcereal-dev_1.2.1-2_amd64.deb && \
 dpkg --add-architecture amd64 && \
 dpkg -i libcereal-dev_1.2.1-2_amd64.deb && \
 echo "########################### Cmake ###########################" && \
 wget https://github.com/Kitware/CMake/releases/download/v3.18.1/cmake-3.18.1.tar.gz && \
 tar -xzvf cmake-3.18.1.tar.gz && \
 rm cmake-3.18.1.tar.gz && \
 cd cmake-3.18.1 && \
 ./bootstrap && \
 make && \
 make install && \
 cd .. && \
 echo "**** link libftdi libs ****" && \
 ln -s /usr/lib/libftdi1.so /usr/lib/libftdi.so && \
 ln -s /usr/lib/libftdi1.a /usr/lib/libftdi.a && \
 ln -s /usr/include/libftdi1/ftdi.h /usr/include/ftdi.h && \
 echo "**** link lua ****" && \
 cd /usr/bin && ln -s lua5.3 lua && \
 cd /usr/lib && ln -s lua5.3/liblua.so liblua5.3.so && \
 echo "**** build domoticz ****" && \
 if [ -z ${DOMOTICZ_COMMIT+x} ]; then \
	DOMOTICZ_COMMIT=$(curl -sX GET https://api.github.com/repos/domoticz/domoticz/commits/development \
	| jq -r '. | .sha'); \
 fi && \
 git clone https://github.com/domoticz/domoticz.git /tmp/domoticz && \
 cd /tmp/domoticz && \
 git checkout ${DOMOTICZ_COMMIT} && \
 cmake \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=/var/lib/domoticz \
	-DUSE_LUA_STATIC=YES \
	-DUSE_BUILTIN_MQTT=YES \
	-DUSE_BUILTIN_SQLITE=NO \
	-DUSE_STATIC_BOOST=NO \
	-DUSE_STATIC_LIBSTDCXX=NO \
	-Wno-dev && \
 make && \
 make install && \
 git clone https://github.com/csigabit/domoticz-espmilighthub /var/lib/domoticz/plugins/ESPMilight && \
 git clone https://github.com/csigabit/domoticz-yamaha /var/lib/domoticz/plugins/yamaha-av-receiver && \
 git clone https://github.com/csigabit/domoticz-zigbee2mqtt /var/lib/domoticz/plugins/zigbee2mqtt && \
 echo "**** determine runtime packages using scanelf ****" && \
 RUNTIME_PACKAGES="$( \
	scanelf --needed --nobanner /var/lib/domoticz/domoticz \
	| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
	| sort -u \
	| xargs -r apk info --installed \
	| sort -u \
	)" && \
 apk add --no-cache \
	$RUNTIME_PACKAGES && \
 echo "**** add abc to dialout and cron group ****" && \
 usermod -a -G 16,20 abc && \
 echo " **** cleanup ****" && \
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/var/cache/apk/* \ 
	/tmp/* \
	/usr/lib/libftdi* \
	/usr/include/ftdi.h

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 1180 6144 11443
VOLUME /config
