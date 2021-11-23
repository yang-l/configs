#!/usr/bin/env bash

# exec "xcode-select --install" first
# to install, run `sudo ./macports.sh‘
port -t install \
     `# replace out-of-date system installed packages` \
     bash bash-completion git gsed coreutils \
     openssl curl-ca-bundle \
     `# addtional packages` \
     tmux fzf ripgrep `# terminal multiplexer & tools` \
     emacs-app `#text editor` \
     `# mas` `# mac app store cli` \
     p7zip `# archive tool` \
     gnupg2 `# asdf/nodejs` \
     stunnel `# tls/ssl tunneling` \
     aspell aspell-dict-en multimarkdown `# emacs/text editing` \
     socat `# networking` \
     qemu `# colima`

# others to install
## xcode / iterm2 / docker (& docker-compose (included)) / virtualbox & vagrant & packer / Terminus TTF / pwsh

# change default bash
## $ echo /opt/local/bin/bash | sudo tee /etc/shells
## $ chsh -s /opt/local/bin/bash
