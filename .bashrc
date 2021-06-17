# .bash_profile is called by login shell (note MacOS is running a login shell for each new terminal window)
# .bashrc is called by interactive non-login shell

[ -f ~/.config/bashrc ] && source ~/.config/bashrc
[ -f ~/.bash_aliases ] && source ~/.bash_aliases
