{ config, pkgs, ... }:

let
  configFilePath = ".ripgreprc";
in {
  home.packages = with pkgs; [
    ripgrep
  ];

  home.sessionVariables = {
    "RIPGREP_CONFIG_PATH" = "${config.home.sessionVariables.XDG_CONFIG_HOME}/${configFilePath}";
  };

  xdg.configFile."${configFilePath}".text = ''
    # make rg also understand POSIX regex, for example from vim not only PCRE2
    --auto-hybrid-regex
    # Treat CRLF as a line ending as well, so $ matches
    --crlf
    # Case insensitive search when pattern only lowercase)
    --smart-case
  '';
}
