{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  imports = [
    ./package
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "jw910731";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

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

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/jw910731/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
