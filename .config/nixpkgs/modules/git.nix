{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    (git.override { svnSupport = false; sendEmailSupport = false; guiSupport = false; } )
    delta
  ];

  home.file.".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${config.home.sessionVariables._BASE_CONFIG_FOLDER_PATH}/.gitconfig";
  home.activation.bash-git-completion = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash'
  '';
  home.activation.zsh-git-completions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh -o ~/.config/zsh/completion/_git --create-dirs'
    $DRY_RUN_CMD bash -c 'set -x ; curl -s https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.config/zsh/completion/git-completion.bash'
  '';
}
