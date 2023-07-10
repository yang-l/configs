{ config, ... }:

{
  home.file = {
    ".ssh/config".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.ssh/config";
    ".ssh/config.d".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.ssh/config.d";
    ".ssh/files".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.ssh/files";
  };
}
