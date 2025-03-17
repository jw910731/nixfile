{ pkgs, ... }:
{
  imports = [
    ../common

    ./package/podman
    ./package/prismlauncher.nix
    ./package/gpg.nix
  ];

  home.packages = with pkgs; [
    podman
    podman-compose
    gdb
    lldb
  ];

  home.language = {
    base = "zh_TW.utf8";
    ctype = "zh_TW.utf8";
    numeric = "zh_TW.utf8";
    time = "zh_TW.utf8";
    collate = "zh_TW.utf8";
    monetary = "zh_TW.utf8";
    messages = "zh_TW.utf8";
    paper = "zh_TW.utf8";
    name = "zh_TW.utf8";
    address = "zh_TW.utf8";
    telephone = "zh_TW.utf8";
    measurement = "zh_TW.utf8";
  };

}
