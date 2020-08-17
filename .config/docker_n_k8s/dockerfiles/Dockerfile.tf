ARG BUILD_BASE_VERSION=3.12
ARG BASE_VERSION=0.13.0

## aws-vault
FROM alpine:${BUILD_BASE_VERSION} as builder
ARG AWS_VAULT_RELEASE=v5.4.4
RUN set -ex && apk add --no-cache curl tar
RUN set -ex \
  && curl -sS -fL -o /aws-vault https://github.com/99designs/aws-vault/releases/download/${AWS_VAULT_RELEASE}/aws-vault-linux-amd64 \
  && chmod +x /aws-vault

## terraform
FROM hashicorp/terraform:${BASE_VERSION}
COPY --from=builder /aws-vault /usr/local/bin/aws-vault
