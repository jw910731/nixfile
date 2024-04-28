#!/usr/bin/env zsh

# `alias` provide custom command aliases.
#
# This file is used as part of `.sh_env`

# == Aliases ==

# Disable correction
alias cd='nocorrect cd'
alias cp='nocorrect cp'
alias gcc='nocorrect gcc'
alias grep='nocorrect grep'
alias ln='nocorrect ln'
alias man='nocorrect man'
alias mkdir='nocorrect mkdir'
alias mv='nocorrect mv'
alias rm='nocorrect rm'

# Disable globbing
alias bower='noglob bower'
alias fc='noglob fc'
alias find='noglob find'
alias ftp='noglob ftp'
alias history='noglob history'
alias locate='noglob locate'
alias rsync='noglob rsync'
alias scp='noglob scp'
alias sftp='noglob sftp'

# Define lazy aliases
alias _='sudo'

# Safe ops. Ask the user before doing anything destructive.
alias rmi="${aliases[rm]:-rm} -i"
alias mvi="${aliases[mv]:-mv} -i"
alias cpi="${aliases[cp]:-cp} -i"
alias lni="${aliases[ln]:-ln} -i"
if zstyle -T ':prezto:module:utility' safe-ops; then
    alias rm="${aliases[rm]:-rm} -i"
    alias mv="${aliases[mv]:-mv} -i"
    alias cp="${aliases[cp]:-cp} -i"
    alias ln="${aliases[ln]:-ln} -i"
fi

# list file aliases
alias ls='lsd --group-dirs first'
alias l='ls -1A'         # Lists in one column, hidden files.
alias ll='ls -lh'        # Lists human readable sizes.
alias lr='ll -R'         # Lists human readable sizes, recursively.
alias la='ll -A'         # Lists human readable sizes, hidden files.
alias lm='la | "$PAGER"' # Lists human readable sizes, hidden files through pager.
alias lx='ll -XB'        # Lists sorted by extension (GNU only).
alias lk='ll -Sr'        # Lists sorted by size, largest last.
alias lt='ll -tr'        # Lists sorted by date, most recent last.
alias lc='lt -c'         # Lists sorted by date, most recent last, shows change time.
alias lu='lt -u'         # Lists sorted by date, most recent last, shows access time.
alias sl='ls'            # I often screw this up.

# grep colors
export GREP_COLOR='37;45'           # BSD.
export GREP_COLORS="mt=$GREP_COLOR" # GNU.
alias grep="${aliases[grep]:-grep} --color=auto"

# File Download
if (( $+commands[curl] )); then
    alias get='curl --continue-at - --location --progress-bar --remote-name --remote-time'
elif (( $+commands[wget] )); then
    alias get='wget --continue --progress=bar --timestamping'
fi

# docker
alias d='docker'
alias dp='docker ps -a'
alias dr='docker rm'
alias di='docker inspect'
alias dvl='docker volume ls'
alias dvi='docker volume inspect'
alias dvp='docker volume inspect --format ''{{"{{"}} .Mountpoint {{"}}"}}'''

# docker-compose
alias dc='docker-compose'
alias dcl='docker-compose logs'
alias dcu='docker-compose up -d'
alias dcr='docker-compose restart'
alias dcub='docker-compose up -d --build'
alias dcb='docker-compose build'
alias dcd='docker-compose down'

# Emacs
alias emacs='emacs -nw'