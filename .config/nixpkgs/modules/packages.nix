{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ## System / replace out-of-dated packages
    cacert
    coreutils-prefixed
    curl
    diffutils
    gnused
    openssl_3_0

    ## Docker
    # (co)lima
    colima # replace docker desktop on mac
    lima
    qemu
    docker-client
    # misc
    ##dive # analysis image size
    #podman
    docker-slim

    ## Emacs
    aspell # spelling check
    aspellDicts.en
    # editor
    #gcc # used during installation and for native-compilation
    #((emacsGcc.override { withGTK3 = false; }).pkgs.withPackages (epkgs: with epkgs; [ vterm ]))
    emacs
    multimarkdown # markdown
    ### LSP
    gopls
    nodePackages.bash-language-server
    nodePackages.dockerfile-language-server-nodejs
    nodePackages.vscode-json-languageserver
    nodePackages.yaml-language-server
    solargraph
    # typescript
    nodePackages.typescript-language-server
    nodePackages.typescript
    nodePackages.prettier
    # python
    autoflake
    nodePackages.pyright
    python310Packages.debugpy
    poetry
    black
    mypy
    python310Packages.flake8

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
