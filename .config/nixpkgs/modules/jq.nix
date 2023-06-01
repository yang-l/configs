{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    jq
  ];

  home.activation.bash-jq-completion = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; /Users/$USER/.nix-profile/bin/curl -s https://gist.githubusercontent.com/albertogalan/957a11d15c385c07d0be219a3fbf984c/raw/f605f3b45c7e7e332cd7a4c139e9191a86ddd00f/jq.bash -o ~/.config/local/bin/jq-completion.bash'
  '';
}
