#!/usr/bin/env bash

# exec "xcode-select --install" first
# to install, run `sudo ./macports.sh‘
port -t install \
     `# replace out-of-date system installed packages` \
     bash git \
     openssl curl-ca-bundle \
     `# addtional packages` \
     emacs-app `#text editor` \
     mas `# mac app store cli` \
     p7zip `# archive tool` \
     `# rbenv ruby-build` `# ruby` \
     the_silver_searcher `# code searching tool` \
     tmux `# terminal multiplexer` \
     socat xorg-server `# docker/x11/gui`

# others to install
## xcode / iterm2 / docker / virtualbox & vagrant & packer / Terminus TTF
