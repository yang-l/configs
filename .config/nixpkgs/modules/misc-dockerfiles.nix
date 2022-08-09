{ config, lib, ... }:

{
  home.activation.dockerfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; [ -L ~/.config/docker_n_k8s ] && rm -f ~/.config/docker_n_k8s ; ln -s "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.config/docker_n_k8s" ~/.config/'
  '';
}
