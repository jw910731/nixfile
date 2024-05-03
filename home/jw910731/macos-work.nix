{ lib, pkgs, ... }:
{
  imports = [
    ./common
    ./darwin
  ];
  home.username = "jerry.wu";
  home.homeDirectory = lib.mkForce "/Users/jerry.wu";
  programs.git = {
    userName = "jerry.wu";
    userEmail = "jerry.wu@appier.com";
    # Sign  
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN95r+6t4LvMMRy6NKW0xnNIjdaXaKDiTzcD6ZozOOHl";
    };
    extraConfig = {
      gpg = {
        format = "ssh";
        ssh = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
    };
  };
  home.packages = with pkgs;[
    trino-cli
    vault
  ];
}

