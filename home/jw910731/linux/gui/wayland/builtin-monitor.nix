{ config, lib, ... }:
let
  inherit (lib) mkOption types;
  nullableOption =
    type: description:
    mkOption {
      type = types.nullOr type;
      default = null;
      inherit description;
    };
in
{
  options.jw.hyprland.builtinMonitor = mkOption {
    default = { };
    description = ''
      Hyprland monitor rule for this machine's builtin panel, set per device.
      Unset fields are resolved at runtime by hyprland.lua, so a machine with
      no entry still gets a working panel. Extra attributes are passed through
      to hl.monitor as they are.
    '';
    type = types.submodule {
      freeformType = types.attrsOf types.anything;
      options = {
        output = nullableOption types.str "Connector name. Unset: detected from sysfs.";
        mode = nullableOption types.str "Mode such as 2560x1600@60. Unset: the panel's preferred mode.";
        scale = nullableOption types.numbers.positive ''
          Must be n/120 and divide both dimensions of the mode exactly, or
          Hyprland snaps it to the nearest such value and shows a warning.
          Unset: Hyprland picks one.
        '';
        vrr = nullableOption (types.ints.between 0 3) "Hyprland VRR mode. Unset: off.";
      };
    };
  };

  config.wayland.windowManager.hyprland.settings.builtin_monitor._var = lib.filterAttrs (
    _: value: value != null
  ) config.jw.hyprland.builtinMonitor;
}
