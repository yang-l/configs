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
