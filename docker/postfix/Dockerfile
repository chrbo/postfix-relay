FROM alpine:latest

MAINTAINER Christian Bode christian.bode@c-b-o.net

RUN apk add --no-cache \
    postfix \
	libsasl \
	cyrus-sasl-login \
	ca-certificates \
	bash \
	util-linux && \
    /usr/bin/newaliases

RUN apk upgrade --no-cache

COPY ./rootfs /

EXPOSE 25

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["postfix", "start-fg"]