{ pkgs, ... }:
{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
    extraPackages = epkgs: [
      epkgs.vterm
    ];
  };
  home.packages = with pkgs; [
    ripgrep
    coreutils # basic GNU utilities
    fd
  ];
}
