{ config, lib, ... }:

{
  home.activation.awsvault = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; [ -L ~/.awsvault ] && rm -f ~/.awsvault ; ln -s "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.awsvault" ~/.awsvault'
  '';
}
