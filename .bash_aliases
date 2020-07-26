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
alias cp='cp -a'
alias grep='grep -JZ --color=auto'
alias grepf='grep -Hno'
alias less='less -N'
alias lsl='ls -lAGh'
alias k9='kill -9'
alias nct='nc -v -w 2'
alias psg='ps auxwww | grep -i'
alias rm='rm -i'
alias myip='dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed -e "s_\\\"\\(.*\\)\\\"_\\1_g" `# DNS based local IP lookup from google`'
alias replstr='__lambda() { find . -type f | xargs perl -pi -e "s/$1/$2/g;" ; } ; __lambda'

# emacs
case "$(uname -s)" in
    Darwin*)      # alias to macports emacs-app's emacsclient
                  _BASH_ALIAS_EMACSCLIENT='/Applications/MacPorts/Emacs.app/Contents/MacOS/bin/emacsclient'
                  _BASH_ALIAS_EMACS='/Applications/MacPorts/Emacs.app/Contents/MacOS/Emacs'
                  ;;
    Linux* | *)   _BASH_ALIAS_EMACSCLIENT='/usr/bin/emacsclient' ;;
esac

alias ecf="${_BASH_ALIAS_EMACSCLIENT} -c -n -a ''"
alias ect="${_BASH_ALIAS_EMACSCLIENT} -t -a ''"
alias eck="${_BASH_ALIAS_EMACSCLIENT} -e '(kill-emacs)'"

if [ ! -z "${_BASH_ALIAS_EMACS}" ] ; then
   alias et="${_BASH_ALIAS_EMACS} -nw"
   alias ef="${_BASH_ALIAS_EMACS}"
fi

# misc
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

# ruby
alias bundle='rbenv exec bundle'
alias bundle-install='rbenv exec bundle install --path vendor/bundle'
alias cap='rbenv exec bundle exec cap'

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
alias aws="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm aws"
if [ -z "$K8S_PROLOAD_AWSCLI_CONTAINER_ID" ] # bash-completion for awscli
then
  complete -C "docker run --rm -e COMP_LINE -e COMP_POINT -v ${HOME}/.aws:/root/.aws:ro --entrypoint /usr/local/bin/aws_completer ops/awscli" aws # start a container everytime (slow)
else
  complete -C "docker exec -e COMP_LINE -e COMP_POINT $K8S_PROLOAD_AWSCLI_CONTAINER_ID /usr/local/bin/aws_completer" aws # with proloading container in k8s
fi

alias cfn-flip="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run --entrypoint cfn-flip -T --rm aws"
alias cfn-lint="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run --entrypoint cfn-lint -T --rm aws"

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
      docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm sam "$@"
      ;;
  esac ;
} ;
__lambda'
### k8s
alias kubectl="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run --rm kubectl"
source ~/.kube/kube-autocomplete
alias k=kubectl
complete -F __start_kubectl k
alias kubeadm="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm kubeadm"
source ~/.config/.k8s/kubeadm-autocomplete
alias helm="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm helm"
source ~/.config/.helm/helm-autocomplete
### terraform
alias terraform="docker-compose -f $HOME/.config/docker_n_k8s/dockerfiles/docker-compose.yml run -T --rm terraform"
alias tf='terraform'

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
fi
