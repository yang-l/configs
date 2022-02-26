{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    zsh
  ];

  programs.zsh = {
    enable = true;

    defaultKeymap = "emacs";
    dotDir = ".config/zsh";

    history = {
      extended = true;
      ignorePatterns = [
        "*--help" "*-h"
        "exit" "clear" "top" "stty*"
        "ls*( )?(-l?(a?(h)))"
        "g?(it)*( )?(?(diff)|?(df?(?(c?(s))|?(s)))|?(po*( )?(-f))|?(l?(?(og)|?(l)|?(o)|?(c?(l))|?(u)|?(s?(-files))))|?(s?(?(tatus)|?(t)))|?(br?(anch))|?(sh?(ow))?(*()HEAD*)|?(fixup)|?(squash)|?(pull)|?(push)|?(ri*( )HEAD*)|?(a*( )*)|?(reflog)|?(m))*( )"
        "docker*( )?(?(ps -a)|?(images)|?(info)|?(rmi*)|?(rm*))"
        "(p)kill" "k9?(+( )*)"
        "tmux?(+( )ls*( )*)"
        "?(terraform|tf)?(+( )?(init|get|plan|apply|destroy))"
        "e?(c)?(f|t|k)"
      ];
      save = 500000;
      size = 500000;
    };

    plugins = [
      {
        name = "zsh-async";
        file = "async.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "mafredri";
          repo = "zsh-async";
          rev = "v1.8.5";
          sha256 = "mpXT3Hoz0ptVOgFMBCuJa0EPkqP4wZLvr81+1uHDlCc=";
        };
      }
      {
        name = "pure-prompt";
        file = "prompt_pure_setup";
        src = pkgs.fetchFromGitHub {
          owner = "sindresorhus";
          repo = "pure";
          rev = "v1.20.1";
          sha256 = "iuLi0o++e0PqK81AKWfIbCV0CTIxq2Oki6U2oEYsr68=";
        };
      }
      {
        name = "evalcache";
        file = "evalcache.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "mroth";
          repo = "evalcache";
          rev = "dce3fd1ca74f791f538942d7e829c5c74c867e61";
          sha256 = "rIng+sqXOmhS6+OTRH5JK9vta4xgtgS/t6/Fw2Wsg0M=";
        };
      }
      {
        name = "fzf-tab";
        file = "fzf-tab.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "e8145d541a35d8a03df49fbbeefa50c4a0076bbf";
          sha256 = "h/3XP/BiNnUgQI29gEBl6RFee77WDhFyvsnTi1eRbKg=";
        };
      }
      {
        name = "zsh-autosuggestions";
        file = "zsh-autosuggestions.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.0";
          sha256 = "KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
        };
      }
      {
        name = "zsh-syntax-highlighting";
        file = "zsh-syntax-highlighting.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "c5ce0014677a0f69a10b676b6038ad127f40c6b1";
          sha256 = "UqeK+xFcKMwdM62syL2xkV8jwkf/NWfubxOTtczWEwA=";
        };
      }
    ];

    shellAliases = {
      g = "git";
      git = "noglob git";
    };

    initExtraFirst = ''
      setopt extended_glob
      path=("''${HOME}/.config/local/bin" $path)
    '';

    initExtraBeforeCompInit = ''
      fpath=(~/.config/zsh/completion $fpath) # for autocompletion

      # asdf-vm
      ## git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.1
      if [ -f ~/.asdf/asdf.sh ]
      then
        source ~/.asdf/asdf.sh
        fpath=(~/.asdf/completions $fpath)
      fi

      # fzf
      export FZF_DEFAULT_COMMAND='rg --files --hidden --no-ignore-vcs --no-messages --smart-case'
      export FZF_DEFAULT_OPTS='--height 30% --layout=reverse --border --info=inline --multi'
      export FZF_CTRL_R_OPTS='--preview "builtin history -r "''${HOME}/.zsh_history" && builtin fc -l $(expr {1} - $(expr $FZF_PREVIEW_LINES / 2)) $(expr {1} + $(expr $FZF_PREVIEW_LINES / 2)) | bat --style=changes --color=always --theme \"Solarized (dark)\""' # show the history around the matched one in the preview window
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      if [ " $(command -v fzf-share)" ]; then
        source "$(fzf-share)/key-bindings.zsh"
        source "$(fzf-share)/completion.zsh"
      fi
    '';

    initExtra = ''
      #####
      ## PROMPT
      #####

      # pure-prompt
      PURE_PROMPT_SYMBOL='$'
      zstyle :prompt:pure:git:stash show yes

      # RPROMPT setup
      function set_rprompt() {
        local _aws_vault_prompt='''
        local _aws_vault_prompt_size=0

        local _zero='%([BSUbfksu]|([FK]|){*})' # https://stackoverflow.com/a/10564427
        local _prompt_size=$(( ''${#''${(S%%)PROMPT//$~_zero/}} - 4 )) # offset by 4 (?) spaces in the second line

        local _column_width=$COLUMNS # total available space
        local _timestamp_width=21 # e.g. ' [22-02-07 21:23:17] '

        local _available_prompt_width=$(( _column_width - _prompt_size ))

        # aws-vault
        if [ -n "''${AWS_VAULT:-}" ] ; then
          local _expiration_delta_s=$(( $(gdate --date="''${AWS_SESSION_EXPIRATION}" +"%s") - $(gdate +"%s") ))
          local _expiration_detal_text="X"
          [[ $_expiration_delta_s -gt 0 ]] && _expiration_detal_text="$(gdate -d @"''${_expiration_delta_s}" +"%-Mm%-Ss")"

          local _aws_vault_text="aws-vault|''${AWS_VAULT} "
          _aws_vault_prompt_size="$(( ''${#_aws_vault_text} + ''${#_expiration_detal_text} + 3 ))"
          _aws_vault_prompt="%B''${_aws_vault_text}%b[%{%F{yellow}%}''${_expiration_detal_text}%{%f%}] "
        fi

        # final calculation
        local _final_leftover_spaces=$(( $_available_prompt_width - $_aws_vault_prompt_size - _timestamp_width ))
        local _final_spaces_padding="$([[ $_final_leftover_spaces -gt 0 ]] && printf '%*s' $_final_leftover_spaces || echo ''')"
        local _final_prompt="''${_aws_vault_prompt}"

        if [[ $_available_prompt_width -gt 0 ]]
        then
          echo -n "%''${_available_prompt_width}<...<''${_final_prompt}''${_final_spaces_padding}[%{%F{yellow}%}$(date '+%y-%m-%d %H:%M:%S')%{%f%}]"
          #                                         | <--- prompt ---> | <--- space padding --->| <------------      Timestamp       ------------> |
        fi
      }

      autoload -U colors
      colors
      setopt PROMPT_SUBST
      _lineup=$'\e[1A' # https://superuser.com/a/737454
      _linedown=$'\e[1B'
      RPROMPT='%{''${_lineup}%}$(set_rprompt)%{''${_linedown}%}'

      #####
      ## HISTORY
      #####

      setopt HIST_NO_STORE
      setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
      setopt HIST_VERIFY               # Don't execute immediately upon history expansion

      zshaddhistory_ignore_pattern() {
	      emulate -L zsh
        setopt localoptions kshglob
	      [[ $(echo $1 | tr -d '\n') != ''${~HISTORY_IGNORE} ]] # https://unix.stackexchange.com/a/593637
      }
      zshaddhistory_functions+=( zshaddhistory_ignore_pattern )

      precmd_history_file_backup() {
        if [ ! -f "$HISTFILE" ] || [ $(wc -l < $HISTFILE) -lt '10' ]
        then
          fc -W
        fi
        cp "$HISTFILE" ~/.config/hist_backup/.zsh_history.$(date +%y%m%d)
      }
      precmd_functions+=( precmd_history_file_backup )

      #####
      ## SETUP
      #####

      # zsh-autosuggestions
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

      # autocompletion
      setopt noautomenu # don't autocomplete prompt
      setopt nomenucomplete
      _comp_options+=(globdots) # show hidden files and directories
      zstyle ':completion:*' insert-tab false # no tab when no char to the left of the cursor

      # evalcache
      ZSH_EVALCACHE_DIR="''${ZDOTDIR:-~/.config/zsh}/.zsh-evalcache"

      # asdf-vm
      if [ "$(command -v asdf)" ]
      then
        # asdf-direnv
        export DIRENV_LOG_FORMAT=""
        _evalcache asdf exec direnv hook zsh
      fi

      # aws-vault
      [ "$(command -v aws-vault)" ] && _evalcache aws-vault --completion-script-zsh

      # emacs
      ## lsp / https://emacs-lsp.github.io/lsp-mode/page/performance/#use-plists-for-deserialization
      export LSP_USE_PLISTS=true
    '';

    loginExtra = ''
      # https://htr3n.github.io/2018/07/faster-zsh/#compiling-completion-dumped-files
      # Execute code in the background to not affect the current session
      {
        # Compile zcompdump, if modified, to increase startup speed.
        zcompdump="''${ZDOTDIR:-~/.config/zsh}/.zcompdump"
        if [[ -s "$zcompdump" && (! -s "''${zcompdump}.zwc" || "$zcompdump" -nt "''${zcompdump}.zwc") ]]; then
          zcompile "$zcompdump"
        fi
      } &!
    '';
  };
}
