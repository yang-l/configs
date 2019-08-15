#!/usr/bin/env bash

set -ex

mkdir -p ~/.config/hist_backup

for i in .keychain
do
    [ -d ~/"${i}" ] && rm -fr ~/"${i}"
    mkdir -p ~/"${i}"
done

# link file
for i in .bash_aliases .bash_profile .inputrc .tmux.conf .Xdefaults .xsessionrc .config/bashrc
do
    [ -L ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}" ~/"${i}"
done

# link folder
for i in .aws .config/awesome .config/iterm2 .config/keychain .config/vagrant
do
    [ -L ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}"/ ~/"${i}"
done

# install git-completion.bash
curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

# terminal truecolor
$( cd "$( dirname "$0" )" && pwd )/.config/terminfo.sh
