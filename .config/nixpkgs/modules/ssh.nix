{ config, ... }:

{
  home.file.".ssh".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.ssh";
}
