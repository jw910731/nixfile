{ pkgs, lib, ... }:
{
  imports = [
    ../common

    ./package.nix
  ];

  home.language = {
    base = "zh_TW.UTF-8";
    ctype = "zh_TW.UTF-8";
    numeric = "zh_TW.UTF-8";
    time = "zh_TW.UTF-8";
    collate = "zh_TW.UTF-8";
    monetary = "zh_TW.UTF-8";
    messages = "zh_TW.UTF-8";
    paper = "zh_TW.UTF-8";
    name = "zh_TW.UTF-8";
    address = "zh_TW.UTF-8";
    telephone = "zh_TW.UTF-8";
    measurement = "zh_TW.UTF-8";
  };
}
