#!/usr/bin/env zsh

# `.exports` is used to provide custom variables.

# Editor
export EDITOR=$(which emacs)
export VISUAL="$EDITOR"

# Bat theme
export BAT_THEME='OneHalfDark'

# macOS only
if [[ "$OSTYPE" = darwin* ]]; then
  # Workaround for Ansible forking: https://github.com/ansible/ansible/issues/76322
  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

  # GPG AGENT
  # export SSH_AUTH_SOCK=$HOME/.gnupg/S.gpg-agent.ssh

  # Homebrew
  export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
  export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
  export HOMEBREW_NO_ANALYTICS=1
fi

# grep colors
export GREP_COLOR='37;45'           # BSD.
export GREP_COLORS="mt=$GREP_COLOR" # GNU.

# Zoxide
# https://github.com/ajeetdsouza/zoxide/blob/main/README.md#environment-variables
export _ZO_ECHO=1 # print the matched directory before navigating to it

# Pagers:
export LESS="-R"  # argument to allow less to show colors

# Colored man pages
export LESS_TERMCAP_md=$(tput bold; tput setaf 1)
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_mb=$(tput bold; tput setaf 2)
export LESS_TERMCAP_us=$(tput bold; tput setaf 2)
export LESS_TERMCAP_ue=$(tput rmul; tput sgr0)
export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4)
export LESS_TERMCAP_se=$(tput rmso; tput sgr0)

# Make Python use UTF-8 encoding for output to stdin, stdout, and stderr.
export PYTHONIOENCODING='UTF-8'

# virtualenv
export PIPENV_VENV_IN_PROJECT=true # look for `.venv` dir inside project
export PIPENV_HIDE_EMOJIS=true # no emojis!
export PIPENV_COLORBLIND=true # disables colors, so colorful!
export PIPENV_NOSPIN=true # disables spinner for cleaner logs

# Enable persistent REPL history for `node`.
export NODE_REPL_HISTORY="$HOME/.node_history"

# Use sloppy mode by default, matching web browsers.
export NODE_REPL_MODE='sloppy'
