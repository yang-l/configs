#!/usr/bin/env bash

set -Eeuxo pipefail

err() {
  echo "errexit with status [$?] at line $(caller)" >&2
  awk 'NR>L-5 && NR<L+3 { printf "%-5d%3s%s\n",NR,(NR==L?">> ":""),$0 }' L=$1 $0
}
trap 'err $LINENO' ERR




main() {
  nix-channel --update

  nix flake update nixpkgs --extra-experimental-features "nix-command flakes" --flake "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/.config/nixpkgs/
  nix flake update home-manager --extra-experimental-features "nix-command flakes" --flake "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/.config/nixpkgs/

  make
}
main "$@"
