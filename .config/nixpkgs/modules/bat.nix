{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
  ];

  programs.bat = {
    enable = true;
    config = {
      color = "always";
      pager = "less -FRSX";
      theme = "Solarized (dark)";
    };
  };
}
