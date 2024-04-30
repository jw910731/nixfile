{ lib, pkgs, ... }:
rec {
  imports = [
    ./common
    ./darwin
  ];
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";
  programs.git = {
    userName = "jw910731";
    userEmail = "jw910731@gmail.com";
  };
}
