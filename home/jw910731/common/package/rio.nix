{ pkgs, ... }:
{
  programs.rio = {
    enable = true;
    settings = {
      adaptive-theme = {
        dark = "Japanesque";
        light = "AtomOneLight";
      };
      editor = {
	      program = "zed";
        args = [];
      };
      fonts = {
        family = "Hack Nerd Font";
        size = 14;
      };
      navigation = {
        use-split = false;
        open-config-with-split = false;
      };
      shell = {
        program = "${pkgs.zsh}/bin/zsh";
        args = ["-li"];
      };
      window = {
        opacity = 0.7;
        blur = true;
        macos-use-unified-titlebar = true;
      };
      option-as-alt = "left";
    };
  };
  xdg.configFile."rio/themes" = {
    source = ./rio-theme;
  };
}
