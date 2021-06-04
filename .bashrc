# .bash_profile is called by login shell (note MacOS is running a login shell for each new terminal window)
# .bashrc is called by interactive non-login shell

[ -f ~/.config/bashrc ] && source ~/.config/bashrc
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# MacPorts
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

# local install
export PATH="${HOME}/.config/local/bin:$PATH"
## aws-vault / cf-vault
