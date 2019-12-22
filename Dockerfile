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
EXPOSE 22

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
      rsync \
      openssh

RUN /usr/bin/ssh-keygen -A

RUN /bin/sed -i 's/home\/user:/home\/user:\/bin\/bash/' /etc/passwd \
      && /usr/bin/passwd -u user

COPY app /app

COPY --from=build-img /build/microsocks/microsocks /usr/bin

RUN find /app -name run | xargs chmod a+rx \
      && chmod a+w /app/* \
      && mkdir /logs \
      && chmod a+rwx /logs

ENV OPENVPN_FILE_SUBPATH=pia/uk-london.ovpn \
    OPENVPN_USERNAME=null \
    OPENVPN_PASSWORD=null \
    LOCAL_NETWORK=192.168.1.0/24

RUN mkdir /home/user/.ssh \
      && chmod 700 /home/user/.ssh

COPY ssh_keys/* /home/user/.ssh/

RUN cp /home/user/.ssh/irssi_user.pub /home/user/.ssh/authorized_keys \
      && chmod 600 /home/user/.ssh/irssi_user \
      && chmod 600 /home/user/.ssh/irssi_user.pub /home/user/.ssh/authorized_keys \
      && chown -R user /home/user/.ssh


CMD ["runsvdir", "/app"]
