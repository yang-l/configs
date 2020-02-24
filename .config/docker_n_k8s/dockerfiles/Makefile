.PHONY: build

build: Dockerfile.ansible Dockerfile.aws Dockerfile.k8s
		mkdir -p ~/.config/.helm/{cache,config,data}
		docker-compose build --force-rm --pull
