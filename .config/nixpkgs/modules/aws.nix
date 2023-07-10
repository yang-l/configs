{ config, ... }:

{
  home.file.".aws/config".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.aws/config";
}
