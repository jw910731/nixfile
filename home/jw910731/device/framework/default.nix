{ pkgs, inputs, ... }:
let
  llm-agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  jw.hyprland.builtinMonitor = {
    output = "eDP-1";
    mode = "2880x1920@120";
    scale = 1.5; # 1920x1280 logical
    vrr = 3;
  };

  home.packages = with pkgs; [
    llm-agents.claude-desktop
  ];
  services.flatpak.packages = [
  ];
}
