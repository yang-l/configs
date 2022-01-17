#!/usr/bin/env bash

rm -f /tmp/terminfo_tmp.*
TMP_MI=$(mktemp /tmp/terminfo_tmp.XXXXXX)

infocmp -x xterm-256color > ${TMP_MI}

printf "\tTc,\n" >> ${TMP_MI}

# https://www.gnu.org/software/emacs/manual/html_node/efaq/Colors-on-a-TTY.html
printf '\t%s\n' "setb24=\E[48\:2\:\:%p1%{65536}%/%d\:%p1%{256}%/%{255}%&%d\:%p1%{255}%&%dm," >> ${TMP_MI}
printf '\t%s\n' "setf24=\E[38\:2\:\:%p1%{65536}%/%d\:%p1%{256}%/%{255}%&%d\:%p1%{255}%&%dm," >> ${TMP_MI}

printf '\t%s\n' "setab=\E[%?%p1%{8}%<%t4%p1%d%e48\:2\:\:%p1%{65536}%/%d\:%p1%{256}%/%{255}%&%d\:%p1%{255}%&%d%;m," >> ${TMP_MI}
printf '\t%s\n' "setaf=\E[%?%p1%{8}%<%t3%p1%d%e38\:2\:\:%p1%{65536}%/%d\:%p1%{256}%/%{255}%&%d\:%p1%{255}%&%d%;m," >> ${TMP_MI}

tic -x ${TMP_MI}

rm -f ${TMP_MI}
