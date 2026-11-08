# just is a command runner, Justfile is very similar to Makefile, but simpler.

# Flake-scoped binary caches (nixConfig in flake.nix) are only honoured when
# the invoking user is trusted by the nix daemon. `nh` recipes assume the
# system is already configured (@wheel/@admin are trusted-users); the
# `lswitch` recipes run the build as root so they also work on a stock Nix
# install (e.g. a fresh NixOS) where flakes are off and you are not trusted.
nh_flags := "--accept-flake-config"
bootstrap_flags := "--option accept-flake-config true --option extra-experimental-features 'nix-command flakes'"

############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

home:
  nh home switch '.' -- {{nh_flags}}

[macos]
boot host:
  echo 'macOS do not support boot subcommand'

[linux]
boot host:
  nh os boot -H {{host}} '.' -- {{nh_flags}}

[macos]
switch host:
  nh darwin switch -H {{host}} '.' -- {{nh_flags}}

[macos]
buildaccel-bootstrap host:
  BUILDACCEL_BOOTSTRAP=1 nh darwin switch -H {{host}} '.' -- --impure {{nh_flags}}
  until sudo ssh -o ConnectTimeout=2 linux-builder true 2>/dev/null; do sleep 3; done
  echo "bootstrap done: now run 'just switch {{host}}'"

[macos]
buildaccel-bootstrap host:
  BUILDACCEL_BOOTSTRAP=1 nh darwin switch -H {{host}} '.' -- --impure
  until sudo ssh -o ConnectTimeout=2 linux-builder true 2>/dev/null; do sleep 3; done
  echo "bootstrap done: now run 'just switch {{host}}'"

[linux]
switch host:
  nh os switch -H {{host}} '.' -- {{nh_flags}}

[macos]
rswitch host:
  nh darwin switch -H {{host}} '.' -- --builders '@/etc/nix/machines' --max-jobs 0 {{nh_flags}}

[linux]
rswitch host:
  nh os switch -H {{host}} '.' -- --builders '@/etc/nix/machines' --max-jobs 0 {{nh_flags}}

[macos]
lswitch host:
  sudo darwin-rebuild switch --flake .#{{host}} {{bootstrap_flags}}

[linux]
lswitch host:
  sudo nixos-rebuild switch --flake .#{{host}} {{bootstrap_flags}}

up:
  nix flake update {{nh_flags}}

# Update one or more specific inputs
# Usage: just upp nixpkgs home-manager
upp +inputs:
  nix flake update {{nh_flags}} {{inputs}}

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
  nix fmt {{nh_flags}}

###############################################################
# Quick Test - emacs
###############################################################


emacs-clean:
  rm -rf ${HOME}/.config/doom

emacs-test: emacs-clean
  rsync -avz --copy-links --chmod=Du=trwx,go=rx,Fu=rwx,go=r home/jw910731/common/package/doom ${HOME}/.config
