# just is a command runner, Justfile is very similar to Makefile, but simpler.

############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

switch host:
  if [ {{os()}} = "macos" ]; then \
  darwin-rebuild switch --flake .#{{host}}; \
  fi
  if [ {{os()}} = "linux" ]; then \
  nh os switch -H {{host}} '.'; \
  fi

up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
upp input:
  nix flake update {{input}}

history:
  nix profile history --profile /nix/var/nix/profiles/system

repl:
  nix repl -f flake:nixpkgs

clean:
  nh clean all -v --ask

############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
  # format the nix files in this repo
  nix fmt


###############################################################
# Quick Test - Neovim
###############################################################


emacs-clean:
  rm -rf ${HOME}/.config/doom

emacs-test: emacs-clean
  rsync -avz --copy-links --chmod=Du=trwx,go=rx,Fu=rwx,go=r home/jw910731/common/package/doom ${HOME}/.config
