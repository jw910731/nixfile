{ lib, pkgs, ... }:
{
  imports = [
    ./package.nix
  ];
  xsession.windowManager.i3 = {
    enable = true;
    config = lib.mkForce null; # ignores all home-manager's default i3 config
    extraConfig = builtins.readFile ./configs/i3-config;
  };
  xsession.windowManager.command = lib.mkForce "${pkgs.i3}/bin/i3 --shmlog-size=26214400";

  home.file = {
    ".config/polybar/polybar.ini".source = ./configs/polybar.ini;
    ".config/dunst/dunstrc".source = ./configs/dunstrc;
    ".config/rofi" = {
      source = ./configs/rofi;
      recursive = true;
    };
    ".config/i3/polybar_script" = {
      source = ./configs/polybar-script;
      recursive = true;
      executable = true;
    };

    ".config/i3/picom.conf".source = ./configs/picom.conf;
  };

  xresources.extraConfig = builtins.readFile ./configs/Xresources;

  programs.rofi = {
    enable = true;
    plugins = [
      pkgs.rofi-calc
    ];
  };
}
