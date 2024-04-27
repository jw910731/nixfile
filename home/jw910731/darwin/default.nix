{ pkgs, ... }:
{
  imports = [
    ../common
  ];

  home.packages = with pkgs;[
    _1password-gui
    telegram-desktop
  ];
}
