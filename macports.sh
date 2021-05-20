#!/usr/bin/env bash

# exec "xcode-select --install" first
# to install, run `sudo ./macports.sh‘
port -t install \
     `# replace out-of-date system installed packages` \
     bash bash-completion git gsed coreutils \
     openssl curl-ca-bundle \
     `# addtional packages` \
     python39 py39-virtualenv `# python` \
     tmux `# terminal multiplexer` \
     emacs-app `#text editor` \
     `# mas` `# mac app store cli` \
     p7zip `# archive tool` \
     `# rbenv ruby-build` `# ruby` \
     `# the_silver_searcher` `# code searching tool` \
     `# socat xorg-server` `# docker/x11/gui` \
     `# pwsh` `# by emacs lsp-pwsh` \
     `# go` `# golang`

# python setup
sudo port select --set python python39
sudo port select --set python3 python39

# others to install
## xcode / iterm2 / docker (& docker-compose (included)) / virtualbox & vagrant & packer / Terminus TTF / pwsh

# change default bash
## $ echo /opt/local/bin/bash | sudo tee /etc/shells
## $ chsh -s /opt/local/bin/bash
