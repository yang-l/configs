{ ... }:

{
  xdg.configFile."docker_n_k8s" = {
    source = ../../../.config/docker_n_k8s;
    recursive = true;
  };
}
