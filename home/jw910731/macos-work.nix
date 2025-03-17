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
    extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };
  home.packages = with pkgs;[
    trino-cli
    vault
  ];
}

