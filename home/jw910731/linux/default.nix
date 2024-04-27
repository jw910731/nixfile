{ pkgs, ... }:
{
  imports = [
    ../common

    ./package/xsession
    ./package/fcitx5
    ./package/podman
    ./package/prismlauncher.nix
  ];

  home.packages = with pkgs;[
    brave
    (wrapOBS { plugins = [ obs-studio-plugins.obs-vaapi ]; })
    noto-fonts-cjk
    pinentry-qt
    prismlauncher
    pavucontrol
    podman
    podman-compose
    gdb
    lldb
  ];
}
