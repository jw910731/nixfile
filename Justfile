# just is a command runner, Justfile is very similar to Makefile, but simpler.

############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

[macos]
switch host:
  nh darwin switch -H {{host}} '.'

[linux]
switch host:
  nh os switch -H {{host}} '.'

[macos]
rswitch host:
  nh darwin switch -H {{host}} '.' -- --builders '@/etc/nix/machines' --max-jobs 0

[linux]
rswitch host:
  nh os switch -H {{host}} '.' -- --builders '@/etc/nix/machines' --max-jobs 0

[macos]
lswitch host:
  darwin-rebuild switch --flake .#{{host}}

[linux]
lswitch host:
  nixos-rebuild switch --flake .#{{host}}

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
