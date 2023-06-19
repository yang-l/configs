{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    asdf-vm
    gnupg # for asdf/nodejs
  ];

  home.file = {
    ".asdfrc".source = ../../../.asdfrc;
    ".default-gems".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.default-gems";
    ".default-npm-packages".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.default-npm-packages";
    ".default-python-packages".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.default-python-packages";
    ".tool-versions".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.tool-versions";
    ".asdf/nixsrc".source = config.lib.file.mkOutOfStoreSymlink "${pkgs.asdf-vm}";
  };
}
