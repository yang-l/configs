#!/usr/bin/env bash

rm -f /tmp/terminfo_tmp.*
TMP_MI=$(mktemp /tmp/terminfo_tmp.XXXXXX)

infocmp -x xterm-256color > ${TMP_MI}

printf "\tTc,\n" >> ${TMP_MI}

# This one is for iTerm2 under macOS, may require changes under Linux
# only work with macports emacs-app "sudo port install emacs-app"
printf '\t%s\n' "setb24=\E[48:2:%p1%{65536}%/%d:%p1%{256}%/%{255}%&%d:%p1%{255}%&%dm," >> ${TMP_MI}
printf '\t%s\n' "setf24=\E[38:2:%p1%{65536}%/%d:%p1%{256}%/%{255}%&%d:%p1%{255}%&%dm," >> ${TMP_MI}

tic -x ${TMP_MI}

rm -f ${TMP_MI}
