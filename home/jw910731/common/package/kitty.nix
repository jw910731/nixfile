{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = "Hack Nerd Font";
      package = (pkgs.nerdfonts.override { fonts = [ "Hack" ]; });
      size = 14.0;
    };
    themeFile = "Japanesque";
    settings = {
      "background_opacity" = "0.95";
      "scrollback_lines" = 2000;
      "allow_remote_control" = true;
      "macos_option_as_alt" = "both";
      "editor" = ".";
      "term" = "xterm-256color";
      "tab_bar_style" = "powerline";
    };
  };
}
