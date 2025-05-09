# just is a command runner, Justfile is very similar to Makefile, but simpler.

############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

switch host:
  if [ {{os()}} = "macos" ]; then \
  nh darwin switch -H {{host}} '.'; \
  fi
  if [ {{os()}} = "linux" ]; then \
  nh os switch -H {{host}} '.'; \
  fi

lswitch host:
  if [ {{os()}} = "macos" ]; then \
  darwin-rebuild switch --flake .#{{host}}; \
  fi
  if [ {{os()}} = "linux" ]; then \
  nixos-rebuild switch --flake .#{{host}}; \
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
  nh clean all --nogcroots --ask

deepclean:
  nh clean all --ask

############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
  nix fmt

###############################################################
# Quick Test - emacs
###############################################################


emacs-clean:
  rm -rf ${HOME}/.config/doom

emacs-test: emacs-clean
  rsync -avz --copy-links --chmod=Du=trwx,go=rx,Fu=rwx,go=r home/jw910731/common/package/doom ${HOME}/.config
