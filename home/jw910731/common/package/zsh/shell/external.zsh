#!/usr/bin/env zsh

( gpg-agent --daemon > /dev/null 2>&1 & )

# zsh-auto-notify (https://github.com/MichaelAquilina/zsh-auto-notify)
AUTO_NOTIFY_IGNORE+=("tmux" "bat" "emacs" "joe" "vim")

# macOS only
if [[ "$OSTYPE" = darwin* ]]; then
  # OrbStack
  if test -f ~/.orbstack/shell/init.zsh; then
    source ~/.orbstack/shell/init.zsh 2>/dev/null || :
  fi
fi

# forgit (https://github.com/wfxr/forgit)

# --ansi is required for forgit to display colors

export FORGIT_FZF_DEFAULT_OPTS="
  --ansi
  --exact
  --border
  --cycle
  --reverse
  --height '80%'
  --preview-window='right:55%:nohidden:nowrap'
"

# fzf (https://github.com/junegunn/fzf)

typeset -AU __FZF

__FZF[PREVIEW_DIR]="lsd --tree --icon always --depth 2 --color=always --timesort"

# TAB / Shift-TAB: multiple selections
# ^S: preview page up, ^D: preview page down
# ?: toggle preview window
# ^O: open with $VISUAL (`code` on macOS)
export FZF_DEFAULT_OPTS="
  --border
  --inline-info
  --reverse
  --tabstop 2
  --multi
  --prompt='» '
  --pointer=' '
  --marker='✓ '
  --bind 'ctrl-s:preview-page-up'
  --bind 'ctrl-d:preview-page-down'
  --bind 'ctrl-o:execute($VISUAL {})+abort'
  --bind '?:toggle-preview'"

#FIXME: file type
export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || cat {} || ${__FZF[PREVIEW_DIR]} {}"

export FZF_CTRL_T_OPTS="
  --preview '($FZF_PREVIEW_COMMAND)'
  --preview-window right:60%:border"

export FZF_CTRL_R_OPTS="
  --layout default
  --height 20
  --preview 'echo {}'
  --preview-window down:3:wrap:hidden
  --bind '?:toggle-preview,ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --header 'Press ^Y to copy command into clipboard'"

export FZF_ALT_C_OPTS="--preview '${__FZF[PREVIEW_DIR]} {}'"

export FZF_COMPLETION_OPTS='+c -x'

zstyle ':fzf-tab:*' fzf-command fzf

# env
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
	fzf-preview 'echo ${(P)word}'

# preview for ls, lsd, z, and cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -1 --icon=always --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'lsd -1 --icon=always --color=always $realpath'
zstyle ':fzf-tab:complete:lsd:*' fzf-preview 'lsd -1 --icon=always --color=always $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'lsd -1 --icon=always --color=always $realpath'

# kill/ps
zstyle ':fzf-tab:complete:(kill|ps):*' fzf-flags \
  --height=20 \
  --preview-window 'down:3:wrap'

if [[ "$OSTYPE" = darwin* ]]; then
  zstyle ':completion:*:processes-names' command "ps -wwrcau$USER -o comm | uniq" # killall
  zstyle ':completion:*:*:*:*:processes' command "ps -wwrcau$USER -o pid,user,%cpu,%mem,stat,comm"
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
    '[[ $group == "[process ID]" ]] && ps -wwp$word -o comm='
fi

if [[ "$OSTYPE" = solaris* ]]; then
  zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm"
fi

if [[ "$OSTYPE" = linux* ]]; then
  zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
    '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
fi