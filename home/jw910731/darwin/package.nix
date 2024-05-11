{ pkgs, ... }:
{
  # Fix macOS man page
  programs.man.enable = false;
  home.extraOutputsToInstall = [ "man" ];
}
