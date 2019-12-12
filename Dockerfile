FROM alpine as build-img

RUN set -x \ 
      && apk update \
      && apk --update add --no-cache git build-base

RUN mkdir /build
WORKDIR /build

RUN git clone https://github.com/rofl0r/microsocks.git \
      && cd microsocks \
      && make



FROM irssi:alpine

EXPOSE 8080
EXPOSE 18080

USER root
ARG release=2.6.1

RUN set -x \
	&& apk --no-cache add \
	perl-archive-zip \
	perl-digest-sha1 \
	perl-html-parser \
	perl-json \
	perl-net-ssleay \
	perl-xml-libxml

USER user

RUN wget https://github.com/autodl-community/autodl-irssi/releases/download/${release}/autodl-irssi-v${release}.zip -O /tmp/autodl-irssi.zip \
	&& mkdir -p ${HOME}/.irssi/scripts/autorun \
	&& unzip -o /tmp/autodl-irssi.zip -d ${HOME}/.irssi/scripts \
	&& cp ${HOME}/.irssi/scripts/autodl-irssi.pl ${HOME}/.irssi/scripts/autorun/autodl-irssi.pl \
	&& mkdir ${HOME}/.autodl \
	&& rm /tmp/autodl-irssi.zip

USER root

RUN apk --update --no-cache add \
      privoxy \
      openvpn \
      runit \
      screen \
      bash \
      rsync

COPY app /app

COPY --from=build-img /build/microsocks/microsocks /usr/bin

RUN find /app -name run | xargs chmod a+rx \
      && chmod a+w /app/* \
      && mkdir /app-config \
      && chmod a+rwx /app-config \
      && mkdir /logs \
      && chmod a+rwx /logs

ENV OPENVPN_FILE_SUBPATH=pia/uk-london.ovpn \
    OPENVPN_USERNAME=null \
    OPENVPN_PASSWORD=null \
    LOCAL_NETWORK=192.168.1.0/24

CMD ["runsvdir", "/app"]
