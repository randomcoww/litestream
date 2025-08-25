ARG VERSION
FROM docker.io/litestream/litestream:$VERSION

ARG TRUSTED_CA

RUN set -x \
  \
  && apk add --no-cache \
    ca-certificates \
  \
  && mkdir -p /usr/local/share/ca-certificates \
  && echo -e "$TRUSTED_CA" > /usr/local/share/ca-certificates/ca-cert.pem \
  && update-ca-certificates

ENTRYPOINT ["litestream"]