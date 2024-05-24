FROM instrumentisto/opendkim:alpine

MAINTAINER Christian Bode christian.bode@c-b-o.net

RUN apk update && \
    apk upgrade && \
    apk add --no-cache bash util-linux

Copy ./rootfs /

RUN chmod +x /usr/local/bin/createOpenDkimConfig.sh
