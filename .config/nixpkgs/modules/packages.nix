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
    colima # replace docker desktop on mac
    lima
    qemu
    dive # analysis image size

    ## Emacs
    aspell # spelling check
    aspellDicts.en
    emacs # editor
    multimarkdown # markdown

    ## Misc
    gettext # for 'envsubst'
    (p7zip.override { enableUnfree = true; }) # archive tool

    ## Networking
    keychain # ssh
    socat # tcp port forwarder / relay
    stunnel # tls/ssl wrapper

    ## Security
    john # John the Ripper password auditing and recovery tool
  ];
}
