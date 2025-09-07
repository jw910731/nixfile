{ pkgs, ... }:
{
  # Fix macOS man page
  programs.man.enable = false;
  home.extraOutputsToInstall = [ "man" ];

  programs.kitty = {
    keybindings = {
      "ctrl+shift+minus" = "no_op";
      "ctrl+shift+equal" = "no_op";
    };
    settings = {
      "macos_option_as_alt" = "both";
      "macos_traditional_fullscreen" = true;
      "macos_show_window_title_in" = "window";
      "macos_menubar_title_max_length" = 100;
      "macos_colorspace" = "default";
    };
    darwinLaunchOptions = [
      "--single-instance"
    ];
    package = derivation {
      name = "empty";
      builder = "${pkgs.uutils-coreutils-noprefix}/bin/mkdir";
      args = [ "${builtins.placeholder "out"}" ];
      system = pkgs.system;
    };
  };
}
