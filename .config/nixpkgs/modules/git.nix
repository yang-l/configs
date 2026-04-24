{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    (git.override { svnSupport = false; sendEmailSupport = false; guiSupport = false; } )
    delta
    gitleaks
  ];

  home.file = {
    ".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.gitconfig";
    ".config/git/ignore".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.config/git/ignore";
    ".git-templates/hooks" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.git-templates/hooks";
      recursive = true;
    };
  };

  home.activation.bash-git-completion = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; /Users/$USER/.nix-profile/bin/curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash'
  '';
}
