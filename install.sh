#!/usr/bin/env bash

for i in .config/awesome
do
    [ -d ~/"${i}" ] && rm -fr ~/"${i}"
    mkdir -p ~/"${i}"
done

for i in .bash_aliases .bash_profile .tmux.conf .Xdefaults .xsessionrc .config/awesome/rc.lua .config/bashrc
do
    [ -e ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}" ~/"${i}"
done
