.PHONY: build

build: Dockerfile.ansible Dockerfile.aws Dockerfile.k8s
		mkdir -p ~/.helm/{cache,config,data}
		docker-compose build --force-rm --pull
