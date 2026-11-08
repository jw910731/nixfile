{ ... }:
{
  jw.hyprland.builtinMonitor = {
    output = "eDP-1";
    mode = "2560x1600@60";
    scale = 1.6; # 1600x1000 logical; 1.5 is not valid on this panel
    vrr = 0; # unsupported
  };

  services.flatpak.packages = [
  ];
}
