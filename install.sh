#!/usr/bin/env bash

set -ex

# for i in .config/hist_backup `# bash history backup` .config/local/bin .bundle `# bundler`
# do
#     mkdir -p ~/"${i}"
# done
#
# for i in $(ls .config/local/bin)
# do
#     [ -L ~/.config/local/bin/"${i}" ] && rm -f ~/.config/local/bin/"${i}"
#     ln -s $(pwd)/.config/local/bin/"${i}" ~/.config/local/bin/"${i}"
# done
#
# # ssh keychain setup
# for i in .keychain
# do
#     [ -d ~/"${i}" ] && rm -fr ~/"${i}"
#     mkdir -p ~/"${i}"
# done
#
# # link files
# for i in .asdfrc .bash_aliases .bash_profile .bashrc .default-gems .default-npm-packages .default-python-packages .envrc .inputrc .tmux.conf .tool-versions .Xdefaults .xsessionrc .bundle/config .config/bashrc
# do
#     [ -L ~/"${i}" ] && rm -f ~/"${i}"
#     ln -s $(pwd)/"${i}" ~/"${i}"
# done
#
# # link folders
# for i in .aws .awsvault .config/awesome .config/direnv .config/docker_n_k8s .config/iterm2 .config/keychain .config/vagrant
# do
#     [ -L ~/"${i}" ] && rm -f ~/"${i}"
#     ln -s $(pwd)/"${i}"/ ~/"${i}"
# done
#
# # git highlight
# for i in /opt/local/share/git/contrib/diff-highlight/diff-highlight
# do
#     [ -L ~/.config/local/bin/diff-highlight ] && rm -f ~/.config/local/bin/diff-highlight
#     [ -f "${i}" ] && ln -s "${i}" ~/.config/local/bin/diff-highlight
# done
#
# # cleanup
# for i in Library/Preferences/com.googlecode.iterm2.plist .zprofile .zsh_history
# do
#     [ -f ~/"${i}" ] && rm -f ~/"${i}"
# done
#
# ## To fix/restore preferences from random iterm2 reset, do the following steps
# # $> cp ~/personal/configs/.config/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist
# # $> plutil -convert xml1 ~/Library/Preferences/com.googlecode.iterm2.plist
#
# for i in .zsh_sessions
# do
#     [ -d ~/"${i}" ] && rm -fr ~/"${i}"
# done
#
# # install git-completion.bash
# curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
#
# # terminal truecolor
# $( cd "$( dirname "$0" )" && pwd )/.config/terminfo.sh


# link files
for i in .Xdefaults .xsessionrc
do
    [ -L ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}" ~/"${i}"
done

# link folders
for i in .config/awesome .config/vagrant
do
    [ -L ~/"${i}" ] && rm -f ~/"${i}"
    ln -s $(pwd)/"${i}"/ ~/"${i}"
done
