{ lib, ... }:
{
  imports = [
    ./common
    ./common/git-identity.nix
    ./darwin
  ];
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";
  programs.git.extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
}
