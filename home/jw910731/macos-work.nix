{ lib, pkgs, config, ... }:
{
  imports = [
    ./common

    ./darwin
  ];
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";
  programs.git = {
    userName = "Jerry Wu";
    userEmail = "jw910731@apple.com";
    # Sign
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPUeTUoxHOR/pJkviU2gAgUROvM5rZb5d73ud7HML8B+";
    };
    extraConfig.gpg = {
      format = "ssh";
    };
  };

  home.packages = with pkgs; [
  ];
}
