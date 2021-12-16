{ config, ... }:

{
  home.file.".bundle/config".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.bundle/config";
}
