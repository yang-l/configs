{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ## System / replace out-of-dated packages
    bash
    cacert
    coreutils-prefixed
    curl
    diffutils
    gnused
    openssl_3

    ## Docker
    # colima
    colima # replace docker desktop on mac
    #lima
    #qemu
    docker-client
    # misc
    ##dive # analysis image size
    #podman
    docker-slim

    ## Emacs
    aspell # spelling check
    aspellDicts.en
    # editor
    (emacs.pkgs.withPackages (epkgs: with epkgs; [ treesit-grammars.with-all-grammars ]))
    libvterm-neovim
    multimarkdown # markdown
    ### LSP
    dockerfile-language-server
    gopls
    nodePackages.bash-language-server
    nodePackages.vscode-json-languageserver
    nodePackages.yaml-language-server
    solargraph
    # typescript
    nodePackages.typescript-language-server
    nodePackages.typescript
    nodePackages.prettier
    # python
    autoflake
    pyright
    python310Packages.debugpy
    poetry
    black
    mypy
    python310Packages.flake8

    ## AI
    # github copilot
    #nodejs_24
    copilot-language-server
    # open soruce ai pair
    aider-chat

    ## Misc
    gettext # for 'envsubst'
    (p7zip.override { enableUnfree = true; }) # archive tool

    ## Networking
    #keychain # ssh
    socat # tcp port forwarder / relay
    stunnel # tls/ssl wrapper

    ## Security
    john # John the Ripper password auditing and recovery tool
  ];
}
