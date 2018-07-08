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
alias ecf='emacsclient -c -n'
alias ect='emacsclient -t'
alias genpass='openssl rand -base64'
alias grep='grep -JZ --color=auto'
alias grepf='grep -Hno'
alias less='less -N'
alias openssl_conn="openssl s_client -connect"
alias psg='ps auxwww | grep -i'
alias rm='rm -i'
alias rsync='time rsync -zhcPS'
alias scp='time scp -Cpr -o Compression=yes -o CompressionLevel=9'
alias ssh-bg='ssh -fNC2T'

# ansible
alias ansible-playbook='ansible-playbook -D'

# cert
alias certp='__lambda() { cat $1 | sed "1d" | sed "\$d" | tr -d "\n" ; } ; __lambda'

# ruby
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
