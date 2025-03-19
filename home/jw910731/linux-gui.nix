{
  imports = [
    ./common
    ./common/git-identity.nix

    ./linux
    ./linux/gui
  ];
  home.username = "jw910731";
  home.homeDirectory = "/home/jw910731";
  programs.git = {
    # Sign
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIlmEeuqIj2EQuHMhiua+C34/mibY9KeMwAyQNj299nl";
    };
    extraConfig = {
      gpg = {
        format = "ssh";
        ssh = {
          program = "op-ssh-sign";
        };
      };
    };
  };
}
