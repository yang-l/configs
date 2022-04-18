{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tmux
    tmux-mem-cpu-load
  ];

  home.file.".tmux.conf".source = ../../../.tmux.conf;
}
