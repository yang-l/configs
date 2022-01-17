# Clean all existing alias
unalias -a

alias rdesktop=' \
__lambda() { \
    RDESKTOP_SHARED="Documents/rdesktop" ; \
    [ ! -d "${RDESKTOP_SHARED}" ] && { mkdir -p /home/$(whoami)/"${RDESKTOP_SHARED}" || exit 1 ; } ; \
    rdesktop -a 16 -z -x modem -P \
             -r clipboard:CLIPBOARD \
             -r disk:shared=/home/$(whoami)/"${RDESKTOP_SHARED}" \
             "$@" ; \
} ; \
__lambda'

# bash
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'
alias cat='bat --style=plain'
alias cp='cp -a'
alias diff='diff --color'
alias grep='grep -JZs --color=auto'
alias grepf='grep -Hno'
alias less='less -N'
alias lsl='ls -lAGh'
alias k9='kill -9'
alias nct='nc -v -w 2'
alias nc-server='__lambda() { while true ; do echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l "${1:-80}" ; done ; } ;  __lambda "$@"'
alias sc-proxy='__lambda() { socat -v -d -d TCP-LISTEN:"${1:-8080}",bind=127.0.0.1,fork TCP:"${2:-localhost}":"${3:-80}" ; } ;  __lambda "$@"'
alias psg='ps auxwww | grep -i'
alias rm='rm -i'
alias myip='dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed -e "s_\\\"\\(.*\\)\\\"_\\1_g" `# DNS based local IP lookup from google`'
alias replstr='__lambda() { find . -type f | xargs perl -pi -e "s/$1/$2/g;" ; } ; __lambda'
alias replstr1='__lambda() { LC_ALL=C find . -type f  -exec sed -i '' s/$1/$2/g {} + ; } ; __lambda'
alias shellcheck='__lambda() { docker run -ti --rm -v $(pwd):/mnt koalaman/shellcheck "$@" ; } ; __lambda "$@"'

# emacs
case "$(uname -s)" in
    Darwin*)      # alias to nix emacsMacport
                  _BASH_ALIAS_EMACSCLIENT='emacsclient'
                  _BASH_ALIAS_EMACS="$HOME/.nix-profile/Applications/Emacs.app/Contents/MacOS/Emacs"
                  ;;
    Linux* | *)   _BASH_ALIAS_EMACSCLIENT='/usr/bin/emacsclient' ;;
esac

alias ecf="${_BASH_ALIAS_EMACSCLIENT} -q -c -a ''"
alias ect="${_BASH_ALIAS_EMACSCLIENT} -q -t -a ''"
alias eck="${_BASH_ALIAS_EMACSCLIENT} -q -e '(kill-emacs)'"

if [ ! -z "${_BASH_ALIAS_EMACS}" ] ; then
   alias et="${_BASH_ALIAS_EMACS} -nw"
   alias ef="${_BASH_ALIAS_EMACS}"
fi
alias e=ect

# misc
alias g='git'
alias genpass='openssl rand -base64'
alias rsync='time rsync -zhcPS'
alias scp='time scp -Cpr -o Compression=yes -o CompressionLevel=9'
alias ssh-bg='ssh -fNC2T'

# cert
alias certg='__lambda() { echo "-----BEGIN CERTIFICATE-----" ; fold -w 64 $1 ; echo "-----END CERTIFICATE-----" ; } ; __lambda'
alias certp='__lambda() { cat $1 | sed "1d" | sed "\$d" | tr -d "\n" ; } ; __lambda'
alias openssl_chkcrt='openssl x509 -text -noout -in'
alias openssl_conn='openssl s_client -connect'
alias ssh_getpubkey='__lambda() { ssh-keygen -y -f $1 ; } ; __lambda'
alias openssl_get_pfx_key=' \
__lambda() { \
    openssl pkcs12 -in $1 -nocerts -nodes | sed -ne "/-BEGIN PRIVATE KEY-/,/-END PRIVATE KEY-/p" ; \
} ; \
__lambda'
alias openssl_get_pfx_cert=' \
__lambda() { \
    openssl pkcs12 -in $1 -clcerts -nokeys | sed -ne "/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p" ; \
} ; \
__lambda'
alias openssl_get_pfx_chain=' \
__lambda() { \
    openssl pkcs12 -in $1 -cacerts -nokeys -chain | sed -ne "/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p" ; \
} ; \
__lambda'

# file
alias openssl_sha256='openssl sha256'

# python
alias pyprofile='python -m cProfile'
alias py3profile='python3 -m cProfile'
alias prettyjson='$(which python) -m json.tool'

# docker
## run gui app interactively in docker
alias dockerapp='
__lambda() {
    if [ $(uname -s) == 'Darwin' ]; then
       [[ -z $(ps auxwww | grep -irE "socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\"" | grep -v grep) ]] && ( socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:\"$DISPLAY\" & ) ;
    fi ;

    DOCKER_ARG=$@ ;
    case "$1" in
        firefox)
            DOCKER_ARG="--shm-size=2g -e DISPLAY=\\$HOSTNAME:0 local/firefox:60.3.0esr"
            ;;
        *)
            ;;
    esac ;

    docker run -ti --rm ${DOCKER_ARG} ;
} ;
__lambda'

## dockerised commands
### ansible
alias ansible-ping="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -e ANSIBLE_HOST_KEY_CHECKING=False --entrypoint ansible -T --rm ansible -m ping `# check host connectivity`"
alias ansible-playbook="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm ansible"
alias ansible-setup="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -e ANSIBLE_HOST_KEY_CHECKING=False --entrypoint ansible -T --rm ansible -m setup `# collect host facts`"
### aws
#if [ -z "$K8S_PROLOAD_AWSCLI_CONTAINER_ID" ] # bash-completion for awscli
#then
#  complete -C "docker run --rm -e COMP_LINE -e COMP_POINT -v ${HOME}/.aws:/root/.aws:ro --entrypoint /usr/local/bin/aws_completer ops/awscli" aws # start a container everytime (slow)
#else
#  complete -C "docker exec -e COMP_LINE -e COMP_POINT $K8S_PROLOAD_AWSCLI_CONTAINER_ID /usr/local/bin/aws_completer" aws # with proloading container in k8s
#fi
complete -C $(which aws_completer) aws

#alias cfn-flip="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml --env-file $HOME/.config/docker_n_k8s/dockerfiles/.env run --entrypoint cfn-flip -T --rm aws"
#alias cfn-lint="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml --env-file $HOME/.config/docker_n_k8s/dockerfiles/.env run --entrypoint cfn-lint -T --rm aws"

alias sam='
__lambda() {
  case "$1" in
    local)
      case "$2" in
        invoke)
          docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm sam local $2 -v "${PWD}/.aws-sam/build" ${@:3}
          ;;
        start-api|start-lambda)
          docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm -p 3000:3000 -p 3001:3001 sam local $2 -v "$PWD/.aws-sam/build" --host 0.0.0.0 ${@:3}
          ;;
        *)
          docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm sam "$@"
          ;;
      esac
      ;;
    *)
      docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run $(for i in $(env | grep ^AWS_ | cut -d"=" -f1); do echo -n "-e $i " ; done) -T --rm sam "$@"
      ;;
  esac ;
} ;
__lambda'

#alias aws-vault="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml --env-file $HOME/.config/docker_n_k8s/dockerfiles/.env run --entrypoint aws-vault -T --rm aws"
### k8s
#alias kubectl="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml --env-file $HOME/.config/docker_n_k8s/dockerfiles/.env run -T --rm kubectl" # -T is used by autocomplete
#source ~/.kube/kube-autocomplete
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k
alias kubeadm="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml --env-file $HOME/.config/docker_n_k8s/dockerfiles/.env run -T --rm kubeadm"
source ~/.config/.k8s/kubeadm-autocomplete
alias helm="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml --env-file $HOME/.config/docker_n_k8s/dockerfiles/.env run -T --rm helm"
source ~/.config/.helm/helm-autocomplete
### terraform
alias tg='terragrunt'
alias tf='terraform'
### jupyter
alias jupyter="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run --service-ports -T --rm jupyter"
alias jupyter-console="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run --rm jupyter-console"

### dev
alias bk='docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run --rm bk'
alias redis-cli='docker run -ti --rm redis redis-cli -h host.docker.internal'

# Linux
if [ $(uname -s) == "Linux" ]; then
    # find which process is opening a file without 'lsof' or 'fuser'
    alias lsofp='__lambda() { sudo find /proc -regex "\/proc\/[0-9]+\/fd\/.*" -type l -lname "*$1*" -printf "%p -> %l\n" 2> /dev/null ; } ; __lambda'
fi

# OSX
if [ $(uname -s) == 'Darwin' ]; then
    alias lscreen='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspendy'

    # macports
    alias port_clean='sudo port -f clean --all all `# build file clean up`'
    alias port_depclean='sudo port -f uninstall inactive || true && sudo port -f uninstall leaves `# remove all necessary packages`'
    alias port_uninstall='sudo port uninstall --follow-dependencies'
    alias port_update='sudo port selfupdate && sudo port upgrade outdated || true && sudo port clean --all installed && sudo port -f uninstall inactive'
    alias port_cleanleaves='while sudo port uninstall leaves; do :; done'

    # iterm2
    alias iterm2_reset='~/Library/Preferences/com.googlecode.iterm2.plist && cp ~/.config/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist && plutil -convert xml1 ~/Library/Preferences/com.googlecode.iterm2.plist && pkill iTerm2'

    # colima
    alias colima_start='colima start --with-kubernetes --mount $HOME/devel:w --mount $HOME/personal:w --mount $HOME/.ejson --mount $HOME/.ssh:w'
    source <(colima completion bash)
    source <(limactl completion bash)

    # asdf
    alias asdf_update='asdf update && asdf plugin-update --all'
    alias asdf_direnv_gen='__lambda() { echo "use asdf" > "${1:-.}"/.envrc ; } ; __lambda'
fi

# misc
alias hledger='__lambda() { docker run -ti --rm --entrypoint hledger -v $(pwd):/data dastapov/hledger "$@" ; } ; __lambda "$@"'
