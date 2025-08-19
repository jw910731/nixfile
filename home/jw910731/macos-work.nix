{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./common

    ./1p-sign.nix

    ./darwin
  ];
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";

  programs.git = {
    # Sign
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWoAtGxpKw/xK4SPDUNqeJQCR/foAP1oIAMI+ZFgCa/";
    };
    extraConfig.gpg = {
      format = "ssh";
      ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
    userName = "Jerry Wu";
    userEmail = "jerry.wu@graidtech.com";
  };

  home.packages = with pkgs; [
  ];
}
