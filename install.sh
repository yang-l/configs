#!/usr/bin/env bash

mkdir -p ~/.config/hist_backup

for i in .config/awesome .config/keychain .keychain .aws
do
    [ -d ~/"${i}" ] && rm -fr ~/"${i}"
    mkdir -p ~/"${i}"
done

for i in .bash_aliases .bash_profile .tmux.conf .Xdefaults .xsessionrc .config/awesome/rc.lua .config/bashrc .config/keychain/keychain .aws/config
do
    [ -e ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}" ~/"${i}"
done
