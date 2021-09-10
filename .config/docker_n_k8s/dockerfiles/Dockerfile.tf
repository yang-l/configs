ARG BUILD_BASE_VERSION
ARG TF_VERSION

## aws-vault
FROM alpine:${BUILD_BASE_VERSION} as builder
ARG TG_VERSION
ARG TG_SHA512_SUM
RUN set -ex && apk add --no-cache curl tar
RUN set -ex \
  && curl -sS -fL -o /terragrunt https://github.com/gruntwork-io/terragrunt/releases/download/${TG_VERSION}/terragrunt_linux_amd64 \
  && echo "${TG_SHA512_SUM}  /terragrunt" | sha512sum -c \
  && chmod +x /terragrunt

## terraform
FROM hashicorp/terraform:${TF_VERSION}
RUN apk add --update --no-cache bash jq shellcheck
COPY --from=builder /terragrunt /usr/local/bin/terragrunt
