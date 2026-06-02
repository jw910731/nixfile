{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.emacs.enable = true;

  programs.doom-emacs = {
    enable = true;
    experimentalFetchTree = true; # Disable me when doom-emacs failed while fetching
    emacs = pkgs.emacs-nox;
    extraPackages = epkgs: [ epkgs.vterm ];
    doomDir = ./doom; # or e.g. `./doom.d` for a local configuration
  };

  home.packages = with pkgs; [
    ripgrep
    coreutils # basic GNU utilities
    fd
  ];

}
