{ lib, pkgs, config, ... }:
{
  imports = [
    ./common

    ./darwin
  ];
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";
  
  # Auto managed by internal tool
  programs.git.enable = lib.mkForce false;

  home.packages = with pkgs; [
  ];
}
