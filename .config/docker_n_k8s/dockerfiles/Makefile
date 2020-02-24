.PHONY: build

build: Dockerfile.ansible Dockerfile.aws Dockerfile.k8s
		mkdir -p ~/.config/.helm/{cache,config,data}
		mkdir -p ~/.config/.k8s
		docker-compose build --force-rm --pull
