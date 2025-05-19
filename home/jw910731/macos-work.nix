{ lib, pkgs, ... }:
{
  imports = [
    ./common

    ./darwin
    ./1p-sign.nix
  ];
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";
  programs.git = {
    userName = "Jerry Wu";
    userEmail = "jw910731@apple.com";
    extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
  };
  home.packages = with pkgs; [
  ];
}
