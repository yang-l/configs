{ ... }:

{
  xdg.configFile."local/bin" = {
    source = ../../../.config/local/bin;
    recursive = true;
  };
}
