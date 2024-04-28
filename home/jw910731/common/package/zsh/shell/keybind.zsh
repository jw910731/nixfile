#!/usr/bin/env zsh

# set movement keybind
if [[ "$TERM" == xterm-256color ]]; then
    bindkey '^[^?' backward-kill-word # meta + delete
    bindkey "^[^[[D" backward-word # meta + left arrow
    bindkey "^[^[[C" forward-word # meta + right arrow
else 
    bindkey "^[[3~" delete-char # delete
    bindkey "^[[1;3C" forward-word # meta + right arrow
    bindkey "^[[1;3D" backward-word # meta + left arrow
fi

