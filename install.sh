#!/usr/bin/env bash

set -ex

for i in .config/hist_backup `# bash history backup` .config/local/bin .bundle `# bundler`
do
    mkdir -p ~/"${i}"
done

# ssh keychain setup
for i in .keychain
do
    [ -d ~/"${i}" ] && rm -fr ~/"${i}"
    mkdir -p ~/"${i}"
done

# link files
for i in .asdfrc .bash_aliases .bash_profile .bashrc .default-npm-packages .default-python-packages .inputrc .tmux.conf .tool-versions .Xdefaults .xsessionrc .bundle/config .config/bashrc
do
    [ -L ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}" ~/"${i}"
done

# link folders
for i in .aws .awsvault .config/awesome .config/docker_n_k8s .config/iterm2 .config/keychain .config/vagrant
do
    [ -L ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}"/ ~/"${i}"
done

# cleanup
for i in Library/Preferences/com.googlecode.iterm2.plist .zprofile .zsh_history
do
    [ -f ~/"${i}" ] && rm -f ~/"${i}"
done

for i in .zsh_sessions
do
    [ -d ~/"${i}" ] && rm -fr ~/"${i}"
done

# install git-completion.bash
curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash

# terminal truecolor
$( cd "$( dirname "$0" )" && pwd )/.config/terminfo.sh
