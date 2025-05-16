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
        "sh" "bash" "zsh"
        "ls*( )?(-l?(a?(h)))" "cd*( )?(-)"
        "g?(it)*( )?(?(diff)|?(df?(?(c?(s))|?(s)))|?(po*( )?(-f))|?(l?(?(og)|?(l)|?(o)|?(c?(l))|?(u)|?(s?(-files))))|?(s?(?(tatus)|?(t)))|?(br?(anch))|?(sh?(ow))?(*()HEAD*)|?(fixup)|?(squash)|?(pull)|?(push)|?(ri*( )HEAD*)|?(a*( )*)|?(reflog)|?(m))*( )"
        "docker*( )?(?(ps -a)|?(images)|?(info)|?(rmi*)|?(rm*))"
        "(p)kill" "k9?(+( )*)"
        "tmux?(+( )ls*( )*)"
        "?(terraform|tf)?(+( )?(init|get|plan|apply|destroy))"
        "e?(c)?(f|t|k)"
        "go*( )?(?(build)|?(test))"
      ];
      save = 500000;
      size = 500000;
    };

    plugins = [
      {
        name = "pure-prompt";
        file = "prompt_pure_setup";
        src = pkgs.fetchFromGitHub {
          owner = "sindresorhus";
          repo = "pure";
          rev = "v1.23.0";
          sha256 = "BmQO4xqd/3QnpLUitD2obVxL0UulpboT8jGNEh4ri8k=";
        };
      }
      {
        name = "evalcache";
        file = "evalcache.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "mroth";
          repo = "evalcache";
          rev = "3153dcd77a2c93aa8fdf5d17cece7edb1aa3e040";
          sha256 = "GAjsTQJs9JdBEf9LGurme3zqXN//kVUM2YeBo0sCR2c=";
        };
      }
      {
        # loading before autosuggestion & syntax-highlighting
        name = "fzf-tab";
        file = "fzf-tab.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.1";
          sha256 = "5vQodWvw9akVvvmpVQH0KjdWmCP7vQz2QOK4Yn24MbA=";
        };
      }
      {
        name = "zsh-autosuggestions";
        file = "zsh-autosuggestions.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "c3d4e576c9c86eac62884bd47c01f6faed043fc5";
          sha256 = "B+Kz3B7d97CM/3ztpQyVkE6EfMipVF8Y4HJNfSRXHtU=";
        };
      }
      {
        name = "zsh-syntax-highlighting";
        file = "zsh-syntax-highlighting.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "e0165eaa730dd0fa321a6a6de74f092fe87630b0";
          sha256 = "4rW2N+ankAH4sA6Sa5mr9IKsdAg7WTgrmyqJ2V1vygQ=";
        };
      }
    ];

    shellAliases = {
      # asdf
      asdf_direnv_gen = ''__lambda() { asdf direnv local "$@" ; } ; __lambda'';
      asdf_shell = ''__lambda() { asdf direnv shell "$@" ; } ; __lambda'';
      #asdf_update = ''asdf update && asdf plugin-update --all'';
      # core
      ".."   = ''cd ..'';
      "..."  = ''cd ../..'';
      "...." = ''cd ../../..'';
      ".4"   = ''cd ../../../..'';
      ".5"   = ''cd ../../../../..'';
      clear_history = ''echo "" > ~/.zsh_history & exec $SHELL -l'';
      cp = "cp -a";
      diff = "diff --color";
      grep = "grep -s --color=auto";
      grepf = "grep -Hno";
      less = "less -N";
      ls = "ls --color=auto";
      rm = "rm -i";
      # app
      aws_comp_conf = "complete -C '$(which aws_completer)' aws";
      cat = "bat --color=auto --style=plain";
      catn = "cat -n";
      g = "git";
      git = "noglob git";
      k = "kubectl";
      mycli = ''docker run --rm -ti mycli mycli "$@"'';
      pgcli = ''docker run --rm -ti pgcli pgcli "$@"'';
      tf = "terraform";
      # cert
      openssl_conn = "openssl s_client -showcerts -connect";
      openssl_conn_verify = "openssl s_client -verify_return_error -showcerts -connect";
      openssl_check_cert = "openssl x509 -text -noout -in";
      openssl_extract_certs = ''__lambda() { openssl crl2pkcs7 -nocrl -certfile "$1" | openssl pkcs7 -print_certs -text -noout ; } ; __lambda'';
      openssl_sha256 = "openssl sha256";
      # dev
      shellcheck = ''__lambda() { docker run -ti --rm -v $(pwd):/mnt koalaman/shellcheck "$@" ; } ; __lambda "$@"'';
      json_format = "pbpaste | jq '.' | pbcopy";
      ## python
      pyprofile = "python -m cProfile";
      py3profile = "python3 -m cProfile";
      prettyjson = ''$(which python) -m json.tool'';
      jupyter = "docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run --service-ports -T --rm jupyter";
      jupyter-console = "docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run --rm jupyter-console";
      ## nix
      nix-shell = ''__lambda() {
        local -a ARGS; ARGS=("$@")
        local NIX_SHELL_PACKAGES="''${NIX_SHELL_PACKAGES}"
        while [[ ''${#ARGS[@]} -gt 0 ]] ; do
          key=''${ARGS[1]}
          if [[ $key = "-p" || $key = "--packages" ]] ; then
            NIX_SHELL_PACKAGES+=''${NIX_SHELL_PACKAGES:+ }''${ARGS[2]}
            ARGS=("''${ARGS[@]:1}")
          fi
          ARGS=("''${ARGS[@]:1}")
        done
        NIX_SHELL_PACKAGES="$NIX_SHELL_PACKAGES" command nix-shell "$@" --run zsh ;
      } ; __lambda'';
      # cert/key
      ssh_getpubkey = ''__lambda() { ssh-keygen -y -f $1 ; } ; __lambda'';
      # net
      myip = ''dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed -e "s_\\\"\\(.*\\)\\\"_\\1_g" `# DNS based local IP lookup from google`'';
      nct = "nc -v -w 2";
      nc-server = ''__lambda() { while true ; do echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l "''${1:-80}" ; done ; } ;  __lambda "$@"'';
      rsync = "time rsync -zhcPS";
      sc-proxy = ''__lambda() { socat -v -d -d TCP-LISTEN:"''${1:-8080}",bind=127.0.0.1,fork TCP:"''${2:-localhost}":"''${3:-80}" ; } ;  __lambda "$@"'';
      scp = "time scp -Cpr -o Compression=yes -o CompressionLevel=9";
      ssh-bg = "ssh -fNC2T";
      # misc
      hledger =''__lambda() { docker run -ti --rm --entrypoint hledger -v $(pwd):/data dastapov/hledger "$@" ; } ; __lambda "$@"'';
    };

    localVariables = {
      PURE_CMD_MAX_EXEC_TIME=3;
    };

    completionInit = ''
      # https://gist.github.com/ctechols/ca1035271ad134841284#gistcomment-2308206
      autoload -Uz compinit
      if [[ -n ''${ZDOTDIR:-~/.config/zsh}/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi
    '';

    initContent = let
      earlyInit = lib.mkOrder 500 ''
        setopt extended_glob
        path=("''${HOME}/.config/local/bin" $path)
        setopt interactivecomments # bash-style comments

        # Nix
        [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ] && source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH

        # keybindings
        bindkey "^[[1;3C" forward-word
        bindkey "^[[1;3D" backward-word

        autoload -U select-word-style # bash like moving and editing words
        select-word-style bash
      '';
      beforCompletionInit = lib.mkOrder 550 ''
        fpath=("''${HOME}/.config/zsh/completion" $fpath) # for autocompletion

        # asdf-vm
        if [ -f ~/.asdf/nixsrc/share/asdf-vm/asdf.sh ]
        then
          source $(realpath ~/.asdf/nixsrc/share/asdf-vm/asdf.sh)
          fpath=(''${ASDF_DIR}/completions $fpath)
        fi
        export ASDF_GOLANG_MOD_VERSION_ENABLED=true # https://github.com/kennyp/asdf-golang/pull/101

        # fzf
        export FZF_DEFAULT_COMMAND='rg --files --hidden --no-ignore-vcs --no-messages --smart-case'
        export FZF_DEFAULT_OPTS='--height 30% --layout=reverse --border --info=inline --multi'
        export FZF_CTRL_R_OPTS='--preview "export HISTSIZE=500000 && builtin fc -R "''${HOME}/.zsh_history" && builtin fc -l $(expr {1} - $(expr $FZF_PREVIEW_LINES / 2)) $(expr {1} + $(expr $FZF_PREVIEW_LINES / 2)) | bat --style=changes --color=always --theme \"Solarized (dark)\""' # show the history around the matched one in the preview window
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        if [ " $(command -v fzf-share)" ]; then
          source "$(fzf-share)/key-bindings.zsh"
          source "$(fzf-share)/completion.zsh"
        fi
      '';
      init = lib.mkOrder 1000 ''
        #####
        ## PROMPT
        #####

        # pure-prompt
        PURE_PROMPT_SYMBOL='$'
        zstyle :prompt:pure:git:stash show yes
        zstyle :prompt:pure:environment:nix-shell show no
        prompt_pure_set_title() {} # https://github.com/sindresorhus/pure/wiki/Customizations,-hacks-and-tweaks#disable-pure-terminal-title-updates

        # https://github.com/sindresorhus/pure/wiki/Customizations,-hacks-and-tweaks#include-initial-newline-when-clearing-screen-ctrll
        custom_prompt_pure_clear_screen() {
          zle -I                   # Enable output to terminal.
          print -n '\e[2J\e[4;0H'  # Clear screen and move cursor to (4, 0).
          zle .redisplay           # Redraw prompt.
        }
        zle -N clear-screen custom_prompt_pure_clear_screen

        # RPROMPT setup
        function set_rprompt() {
          local _aws_vault_prompt='''
          local _aws_vault_prompt_size=0

          local _cf_vault_prompt='''
          local _cf_vault_prompt_size=0

          local _nix_shell_prompt='''
          local _nix_shell_prompt_size=0

          local _direnv_prompt='''
          local _direnv_prompt_size=0

          local _pipestatus_prompt='''
          local _pipestatus_prompt_size=0

          local _zero='%([BSUbfksu]|([FK]|){*})' # https://stackoverflow.com/a/10564427
          local _prompt_size=$(( ''${#''${(S%%)PROMPT//$~_zero/}} - 4 )) # offset by 4 (?) spaces in the second line

          local _column_width=$COLUMNS # total available space
          local _timestamp_width=21 # e.g. ' [22-02-07 21:23:17] '

          local _available_prompt_width=$(( _column_width - _prompt_size ))

          # aws-vault
          if [ -n "''${AWS_VAULT:-}" ] ; then
            local _expiration_delta_s=$(( $(gdate --date="''${AWS_CREDENTIAL_EXPIRATION:-$AWS_SESSION_EXPIRATION}" +"%s") - $(gdate +"%s") ))
            local _expiration_detal_text="X"
            [[ $_expiration_delta_s -gt 0 ]] && _expiration_detal_text="$(gdate -d @"''${_expiration_delta_s}" +"%-Hh%-Mm%-Ss")"

            local _aws_vault_text="aws-vault|''${AWS_VAULT} "
            _aws_vault_prompt_size="$(( ''${#_aws_vault_text} + ''${#_expiration_detal_text} + 3 + 2 ))" # 3 is for '[] ' 2 is for '┊ '
            _aws_vault_prompt="┊ %B%F{066}''${_aws_vault_text}%f%b[%{%F{yellow}%}''${_expiration_detal_text}%{%f%}] "
          fi

          # cf-vault
          if [ -n "''${CLOUDFLARE_VAULT_SESSION:-}" ] ; then
             local _cf_vault_text="cf-vault|''${CLOUDFLARE_VAULT_SESSION} "
             _cf_vault_prompt_size="$(( ''${#_cf_vault_text} + 2 ))" # 2 is for '┊ '
             _cf_vault_prompt="┊ %B%F{115}''${_cf_vault_text}%b"
          fi

          # nix-shell
          if [ -n "''${IN_NIX_SHELL:-}" ] ; then
            local _nix_shell_text='nix-shell '
            [ -n "''${NIX_SHELL_PACKAGES:-}" ] && _nix_shell_text="nix-shell(''${NIX_SHELL_PACKAGES}) "
            _nix_shell_prompt_size="$(( ''${#_nix_shell_text} + 2 + _nix_shell_offset ))" # 2 is for '┊ '
            _nix_shell_prompt="┊ %B%F{107}''${_nix_shell_text}%f%b"
          fi

          # direnv
          if [[ -v DIRENV_DIR ]] ; then
            local _direnv_text="direnv|''${DIRENV_DIR##*/} "
            _direnv_prompt_size="$(( ''${#_direnv_text} + 2 ))" # 2 is for '┊ '
            _direnv_prompt="┊ %B%F{130}''${_direnv_text}%f%b"
          fi

          # pipestatus
          if [[ "$_PIPESTATUS" != "0" ]]; then
            _pipestatus_prompt_size="$(( ''${#_PIPESTATUS} + 3 ))" # 3 is for '[] '
            _pipestatus_prompt="%F{$prompt_pure_colors[prompt:error]}[$_PIPESTATUS]%f "
          fi

          # final calculation
          local _home_directory_offset=0
          [[ "$PWD" == "$HOME" ]] && _home_directory_offset=1 # for some unknown reason at the $HOME directory only
          local _final_leftover_spaces=$(( _available_prompt_width - _pipestatus_prompt_size - _direnv_prompt_size - _nix_shell_prompt_size - _aws_vault_prompt_size - _cf_vault_prompt_size - _timestamp_width - _home_directory_offset ))
          local _final_spaces_padding="$([[ $_final_leftover_spaces -gt 0 ]] && printf '%*s' $_final_leftover_spaces)"
          local _final_prompt="''${_pipestatus_prompt}''${_direnv_prompt}''${_nix_shell_prompt}''${_aws_vault_prompt}''${_cf_vault_prompt}"

          if [[ $_available_prompt_width -gt 0 ]]
          then
            echo -n "%$(( _available_prompt_width - 2 ))<...<''${_final_prompt}''${_final_spaces_padding}[%{%F{yellow}%}$(date '+%y-%m-%d %H:%M:%S')%{%f%}]"
            #                                               | <--- prompt ---> | <--- space padding --->| <------------      Timestamp       ------------> |
          fi
        }

        precmd_pipestatus() {
          _PIPESTATUS="''${(j.|.)pipestatus}"
        }
        add-zsh-hook precmd precmd_pipestatus

        setopt promptsubst
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

        zstyle ':completion:*' use-cache on # use cache
        zstyle ':completion:*' cache-path ~/.config/zsh/cache

        # evalcache
        ZSH_EVALCACHE_DIR="''${ZDOTDIR:-~/.config/zsh}/.zsh-evalcache"

        # asdf-vm
        if [ "$(command -v asdf)" ]; then
          if [ "$(command -v direnv)" ]; then
            # asdf-direnv
            export DIRENV_LOG_FORMAT=""
            _evalcache direnv hook zsh
          fi
        fi

        # for compatible bash completion
        autoload bashcompinit && bashcompinit

        # aws-cli
        ## v2
        export AWS_CLI_AUTO_PROMPT=on

        # aws-vault
        [ "$(command -v aws-vault)" ] && _evalcache aws-vault --completion-script-bash

        # colima/lima
        if [[ $(uname) == 'Darwin' ]] && [ "$(command -v colima)" ]; then
           alias colima_start='colima start --cpu 2 --memory 4 --with-kubernetes'
           _evalcache colima completion zsh
           _evalcache limactl completion zsh
           export DOCKER_HOST="unix://''${HOME}/.colima/default/docker.sock"
        fi

        # emacs
        ## lsp / https://emacs-lsp.github.io/lsp-mode/page/performance/#use-plists-for-deserialization
        export LSP_USE_PLISTS=true

        # ## vterm
        # if [[ "$INSIDE_EMACS" = 'vterm' ]] \
        #   && [[ -n "''${EMACS_VTERM_PATH}" ]] \
        #   && [[ -f "''${EMACS_VTERM_PATH}/etc/emacs-vterm-zsh.sh" ]]; then
        #   source "''${EMACS_VTERM_PATH}/etc/emacs-vterm-zsh.sh"
        # fi

        ## alias
        case "$(uname -s)" in
            Darwin*)      # alias to nix emacsMacport
                          _BASH_ALIAS_EMACSCLIENT='emacsclient'
                          _BASH_ALIAS_EMACS="$HOME/.nix-profile/Applications/Emacs.app/Contents/MacOS/Emacs"
                          ;;
            Linux* | *)   _BASH_ALIAS_EMACSCLIENT='/usr/bin/emacsclient' ;;
        esac

        alias ecf="''${_BASH_ALIAS_EMACSCLIENT} -q -c -a '''"
        alias ect="''${_BASH_ALIAS_EMACSCLIENT} -q -t -a '''"
        alias eck="''${_BASH_ALIAS_EMACSCLIENT} -q -e '(kill-emacs)'"

        if [ ! -z "''${_BASH_ALIAS_EMACS}" ] ; then
          alias et="''${_BASH_ALIAS_EMACS} -nw"
          alias ef="''${_BASH_ALIAS_EMACS}"
        fi
        alias e=ect

        # kubectl
        if [ -x "$(command -v kubectl)" ]; then
          _evalcache kubectl completion zsh
          compdef __start_kubectl k
        fi

        # jq
        ## [ -f ~/.config/local/bin/jq-completion.bash ] && source ~/.config/local/bin/jq-completion.bash
      '';
    in
      lib.mkMerge [ earlyInit beforCompletionInit init ];

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

  home.activation.zsh-docker-completion = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; mkdir -p ~/.config/zsh/completion ; /Users/$USER/.nix-profile/bin/curl -s https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker -o ~/.config/zsh/completion/_docker'
  '';

  home.activation.direnv-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD bash -c 'set -x ; mkdir -p ~/.config/direnv/lib/ ; cat <<-EOF | tee ~/.config/direnv/lib/use_asdf.sh
use_asdf() {
  source_env "\$(asdf direnv envrc "\$@")"
}
EOF'
  '';
}
