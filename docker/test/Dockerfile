FROM alpine:latest

RUN apk add --no-cache \
    bash \
    busybox-extras \
    netcat-openbsd \
    openssl

RUN apk upgrade --no-cache

COPY ./rootfs /

RUN chmod +x /usr/local/bin/test.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["test.sh"]
