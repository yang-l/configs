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
alias grep='grep --color=auto'
alias ect='emacsclient -t'
alias ssh-background='ssh -fNC2T'
alias cp='cp -a'
alias rm='rm -i'
alias rsync='time rsync -zhcP'
alias scp='time scp -Cpr -o Compression=yes -o CompressionLevel=9'

# ansible
alias ansible-playbook='ansible-playbook -D'
