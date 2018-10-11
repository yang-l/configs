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
alias k='kill -9'
alias psg='ps auxwww | grep -i'
alias rm='rm -i'

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

# ansible
alias ansible-ping='ANSIBLE_HOST_KEY_CHECKING=False ansible -m ping'
alias ansible-playbook='ansible-playbook -D'
alias ansible-setup='ANSIBLE_HOST_KEY_CHECKING=False ansible -m setup'

# cert
alias certp='__lambda() { cat $1 | sed "1d" | sed "\$d" | tr -d "\n" ; } ; __lambda'
alias openssl_chkcrt='openssl x509 -text -noout -in'
alias openssl_conn='openssl s_client -connect'

# python
alias pyprofile='python -m cProfile'
alias py3profile='python3 -m cProfile'

# ruby
alias bundle='rbenv exec bundle'
alias bundle-install='rbenv exec bundle install --path vendor/bundle'
alias cap='rbenv exec bundle exec cap'

# terraform
alias tf="terraform"

# Linux
if [ $(uname -s) == "Linux" ]; then
    # find which process is opening a file without 'lsof' or 'fuser'
    alias lsofp='__lambda() { sudo find /proc -regex "\/proc\/[0-9]+\/fd\/.*" -type l -lname "*$1*" -printf "%p -> %l\n" 2> /dev/null ; } ; __lambda'
fi

# OSX
if [ $(uname -s) == 'Darwin' ]; then
    alias lscreen='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspendy'
fi
