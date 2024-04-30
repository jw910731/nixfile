{ lib, pkgs, ... }:
rec {
  imports = [
    ./common
    ./common/git-identity.nix
    ./darwin
  ];
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";
  programs.git = {
    userName = "jerry.wu";
    userEmail = "jerry.wu@appier.com";
    # Sign  
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIlmEeuqIj2EQuHMhiua+C34/mibY9KeMwAyQNj299nl";
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
}
