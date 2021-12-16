{ config, ... }:

{
  home.file.".aws" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.aws";
    recursive = true;
  };
}
