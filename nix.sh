#!/usr/bin/env bash

set -ex

cp ~/.config/iterm2/com.googlecode.iterm2.plist ~/personal/configs/.config/iterm2/com.googlecode.iterm2.plist

export __FULL_BASE_FOLDER_PATH=$( cd "$( dirname "$0" )" && pwd )

cd $__FULL_BASE_FOLDER_PATH

envsubst '$__FULL_BASE_FOLDER_PATH' < $__FULL_BASE_FOLDER_PATH/.config/nixpkgs/flake.nix.template > $__FULL_BASE_FOLDER_PATH/.config/nixpkgs/flake.nix

home-manager "${1:-build}" --flake $__FULL_BASE_FOLDER_PATH/.config/nixpkgs/#macbook-pro -v

rm -f result
