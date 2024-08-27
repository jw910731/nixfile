{ pkgs, ... }:
{
  # Fix macOS man page
  programs.man.enable = false;
  home.extraOutputsToInstall = [ "man" ];

  programs.kitty.keybindings = {
    "ctrl+shift+minus" = "no_op";
    "ctrl+shift+equal" = "no_op";
  };

  programs.kitty.package = derivation {
    name = "empty";
    builder = "${pkgs.bash}/bin/bash";
    args = [ "-c" ''declare -xp
    ${pkgs.uutils-coreutils-noprefix}/bin/mkdir $out'' ];
    system = pkgs.system;
  };
}
