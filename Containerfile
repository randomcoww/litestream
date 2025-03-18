FROM hashicorp/terraform:latest as CA
COPY trusted_ca.tf .

ARG AWS_ENDPOINT_URL_S3
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ENV AWS_ENDPOINT_URL_S3=$AWS_ENDPOINT_URL_S3
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

RUN set -x \
  \
  && terraform init \
  && terraform apply -auto-approve \
  && cat outputs/* > ca-cert.pem

# https://github.com/benbjohnson/litestream/blob/main/Dockerfile
FROM golang:1.23 as BUILD

ARG VERSION=main
RUN set -x \
  \
  && git clone --depth=1 -b $VERSION https://github.com/benbjohnson/litestream.git \
  && cd litestream \
  && go build -ldflags "-s -w -X 'main.Version=${VERSION}' -extldflags '-static'" \
    -tags osusergo,netgo,sqlite_omit_load_extension \
    -o /usr/local/bin/litestream ./cmd/litestream

FROM alpine:latest
COPY --from=CA ca-cert.pem /usr/local/share/ca-certificates/
COPY --from=BUILD /usr/local/bin/litestream /usr/local/bin/litestream

RUN set -x \
  \
  && apk add --no-cache \
    ca-certificates \
  \
  && update-ca-certificates

ENTRYPOINT ["litestream"]