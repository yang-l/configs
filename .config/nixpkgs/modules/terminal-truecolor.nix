{ config, lib, ... }:

{
  home.activation.terminal-truecolor = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; ${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.config/terminfo.sh'
  '';
}
