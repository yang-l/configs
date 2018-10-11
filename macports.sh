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
     `# rbenv ruby-build` `# ruby` \
     the_silver_searcher `# code searching tool` \
     tmux `# terminal multiplexer`

# others to install
## xcode / iterm2 / docker / virtualbox & vagrant
