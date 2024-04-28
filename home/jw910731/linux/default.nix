{ pkgs, ... }:
{
  imports = [
    ../common

    ./package/xsession
    ./package/fcitx5
    ./package/podman
    ./package/prismlauncher.nix
    ./package/gnupg.nix
  ];

  home.packages = with pkgs;[
    podman
    podman-compose
    gdb
    lldb
  ];
}
