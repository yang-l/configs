{ lib, ... }:

{
  home.activation.cleanup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; rm -fr ~/.zsh_history ~/.zsh_sessions ~/.zprofile ~/Library/Preferences/com.googlecode.iterm2.plist'
  '';
}
