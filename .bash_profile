# .bash_profile is called by login shell (note MacOS is running a login shell for each new terminal window)
# .bashrc is called by interactive non-login shell

case "$-" in *i*) if [ -r ~/.bashrc ]; then . ~/.bashrc; fi;; esac
