#!/usr/bin/env bash

# exec "xcode-select --install" first
# to install, run `sudo ./macports.sh‘
port -t install \
     `# replace out-of-date system installed packages` \
     bash bash-completion git gsed coreutils \
     openssl curl-ca-bundle \
     `# addtional packages` \
     tmux `# terminal multiplexer` \
     emacs-app `#text editor` \
     `# mas` `# mac app store cli` \
     p7zip `# archive tool` \
     gnupg2 `# asdf/nodejs` \
     stunnel `# tls/ssl tunneling` \
     aspell aspell-dict-en multimarkdown `# emacs/text editing` \
     socat `# networking` \
     qemu `# colima` \
     `# the_silver_searcher` `# code searching tool` \
     `# xorg-server` `# docker/x11/gui` \
     `# pwsh` `# by emacs lsp-pwsh`

# others to install
## xcode / iterm2 / docker (& docker-compose (included)) / virtualbox & vagrant & packer / Terminus TTF / pwsh

# change default bash
## $ echo /opt/local/bin/bash | sudo tee /etc/shells
## $ chsh -s /opt/local/bin/bash
