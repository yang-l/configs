{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    fzf
  ];

  home.activation.history_backup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; mkdir -p ~/.config/hist_backup'
  '';
}
