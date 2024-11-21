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
        mode = "Plain";
        use-split = false;
        open-config-with-split = false;
      };
      shell = {
        program = "${pkgs.zsh}/bin/zsh";
        args = ["-l" "-c" "${pkgs.zellij}/bin/zellij"];
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
