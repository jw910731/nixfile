{ lib, pkgs, ... }:
{
  imports = [
    ./common

    ./darwin
    ./1p-sign.nix
  ];
  home.username = "jerry.wu";
  home.homeDirectory = lib.mkForce "/Users/jerry.wu";
  programs.git = {
    userName = "";
    userEmail = "";
    extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };
  home.packages = with pkgs; [
  ];
}
