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
  sudo nixos-rebuild switch --flake .#{{host}}; \
  fi

up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
upp input:
  nix flake lock --update-input {{input}}

history:
  nix profile history --profile /nix/var/nix/profiles/system

repl:
  nix repl -f flake:nixpkgs

clean:
  # remove all generations older than 7 days
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

gc:
  # garbage collect all unused nix store entries
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
  # format the nix files in this repo
  nix fmt
