{
  imports = [
    ./common
    ./common/git-identity.nix

    ./linux
    ./linux/gui
  ];
  home.username = "jw910731";
  home.homeDirectory = "/home/jw910731";
  programs.git.extraConfig.gpg.ssh.program = "op-ssh-sign";
}
