{ ... }:
{
  imports = [
    ./package
  ];

  home.username = "jw910731";
  home.homeDirectory = "/home/jw910731";

  home.language = {
    base = "zh_TW.utf8";
    ctype = "zh_TW.utf8";
    numeric = "zh_TW.utf8";
    time = "zh_TW.utf8";
    collate = "zh_TW.utf8";
    monetary = "zh_TW.utf8";
    messages = "zh_TW.utf8";
    paper = "zh_TW.utf8";
    name = "zh_TW.utf8";
    address = "zh_TW.utf8";
    telephone = "zh_TW.utf8";
    measurement = "zh_TW.utf8";
};

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}