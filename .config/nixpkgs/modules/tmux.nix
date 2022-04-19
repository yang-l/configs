{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tmux
    tmux-mem-cpu-load
    # for tmux-network-bandwidth plugin
    coreutils
    gawkInteractive
  ];

  home.file.".tmux.conf".source = ../../../.tmux.conf;
}
