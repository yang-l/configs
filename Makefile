.PHONY: default all build switch

default: build
all: build switch

build:
	./nix.sh

switch:
	./nix.sh switch
