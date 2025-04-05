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

ARG VERSION
FROM docker.io/litestream/litestream:$VERSION
COPY --from=CA ca-cert.pem /usr/local/share/ca-certificates/

RUN set -x \
  \
  && apk add --no-cache \
    ca-certificates \
  \
  && update-ca-certificates

ENTRYPOINT ["litestream"]