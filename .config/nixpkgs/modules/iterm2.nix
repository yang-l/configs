{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    iterm2
    terminus_font_ttf
  ];

  xdg.configFile."iterm2/com.googlecode.iterm2.plist".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.config/iterm2/com.googlecode.iterm2.plist";
}
