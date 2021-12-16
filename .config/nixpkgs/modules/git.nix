{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    git
  ];

  home.file.".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.gitconfig";
  home.activation.git-completion = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash'
  '';
}
