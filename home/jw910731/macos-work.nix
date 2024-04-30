{ lib, pkgs, ... }:
rec {
  imports = [
    ./common
    ./darwin
  ];
  home.username = "jerry.wu";
  home.homeDirectory = lib.mkForce "/Users/jerry.wu";
  programs.git = {
    userName = "jerry.wu";
    userEmail = "jerry.wu@appier.com";
  };
}
