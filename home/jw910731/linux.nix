{
  imports = [
    ./common
    ./common/git-identity.nix
    ./common/git-sendmail.nix

    ./linux
  ];
  home.username = "jw910731";
  home.homeDirectory = "/home/jw910731";
}
