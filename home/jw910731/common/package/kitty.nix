{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    font = {
      name = ''family="Hack Nerd Font"'';
      package = pkgs.nerd-fonts.hack;
      size = 14.0;
    };
    themeFile = "Japanesque";
    settings = {
      "background_opacity" = "0.95";
      "scrollback_lines" = 2000;
      "allow_remote_control" = true;
      "editor" = ".";
      "term" = "xterm-256color";
      "tab_bar_style" = "powerline";
    };
    enableGitIntegration = true;
    shellIntegration = {
      enableZshIntegration = true;
      mode = "no-rc no-complete";
    };
  };
}
