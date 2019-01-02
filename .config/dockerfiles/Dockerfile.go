# `docker build -t local/go-dev:stretch-1.11 -t local/go-dev:latest -f Dockerfile.go .'
FROM golang:stretch

ENV LANG C.UTF-8

# install pkgs
RUN set -eux ; \
  apt-get update ; \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
                  chromedriver ; \
  apt-get --purge autoremove ; \
  apt-get clean ; \
  find /var/cache/apt/archives /var/lib/apt/lists -not -name lock -type f -delete ; \
  rm -rf /tmp/* /var/tmp/*

RUN set -eux ; \
  go get -u -v github.com/sclevine/agouti ; \
  go get -u -v github.com/onsi/ginkgo/ginkgo ; \
  go get -u -v github.com/onsi/gomega
