{
  imports = [
    ./common
    ./common/git-identity.nix

    ./linux
  ];
  home.username = "jw910731";
  home.homeDirectory = "/home/jw910731";
  programs.git = {
    # Sign  
    signing = {
      signByDefault = true;
      key = "16D83FE3495FA263";
    };
  };
}
