{ lib, pkgs, ... }:
rec {
  imports = [
    ./common
    ./darwin
  ];
  home.homeDirectory = lib.mkForce "/Users/jw910731";
}