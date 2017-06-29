#!/usr/bin/env bash

mkdir -p ~/.config/hist_backup

for i in .keychain
do
    [ -d ~/"${i}" ] && rm -fr ~/"${i}"
    mkdir -p ~/"${i}"
done

# link file
for i in .bash_aliases .bash_profile .tmux.conf .Xdefaults .xsessionrc .config/bashrc
do
    [ -e ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}" ~/"${i}"
done

# link folder
for i in .aws .config/awesome .config/iterm2 .config/keychain .config/vagrant
do
    [ -e ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}"/ ~/"${i}"
done
