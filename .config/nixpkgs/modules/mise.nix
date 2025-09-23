{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    mise
    usage # mise shell completion
  ];

  home.file = {
    ".config/mise".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.config/mise";
    ".default-gems".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.default-gems";
    ".default-go-packages".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.default-go-packages";
    ".default-npm-packages".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.default-npm-packages";
    ".default-python-packages".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.default-python-packages";
    ".tool-versions".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.tool-versions";
  };
}
