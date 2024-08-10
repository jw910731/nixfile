{ pkgs, ... }:
{
  # Fix macOS man page
  programs.man.enable = false;
  home.extraOutputsToInstall = [ "man" ];

  programs.kitty.keybindings = {
    "ctrl+shift+minus" = "no_op";
    "ctrl+shift+equal" = "no_op";
  };
}
