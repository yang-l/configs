{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    bashInteractive
    bash-completion
  ];

  home.file = {
    ".bash_aliases".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.bash_aliases";
    ".bash_profile".source = ../../../.bash_profile;
    ".bashrc".source = ../../../.bashrc;
    ".inputrc".source = ../../../.inputrc;
  };
  xdg.configFile."bashrc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.config/bashrc";
}
