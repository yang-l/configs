# This file is called by login shell, whereas .bashrc is called by interactive non-login shell
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi
