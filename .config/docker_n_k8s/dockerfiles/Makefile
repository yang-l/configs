.PHONY: build

build: Dockerfile.ansible Dockerfile.aws Dockerfile.k8s
		docker-compose build --force-rm --pull
