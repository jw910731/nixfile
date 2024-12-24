{...}:
{
  programs.zellij = {
    enable = true;
  };
  xdg.configFile."zellij/config.kdl".source = ./zellij.kdl;
  xdg.configFile."zellij/layouts/terminal_default.kdl".source = ./rio.zellij-layout.kdl;
}
