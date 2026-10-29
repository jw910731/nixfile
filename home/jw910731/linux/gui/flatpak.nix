{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.flatpak = {
    uninstallUnmanaged = true;
    packages = [
      "com.discordapp.Discord"
      "com.valvesoftware.Steam"
      "org.kde.keepsecret"
      "org.localsend.localsend_app"
      "io.bassi.Amberol"
      "org.onlyoffice.desktopeditors"
      "org.videolan.VLC"
      "org.mozilla.thunderbird"
    ];
    # Hyprland uses xwayland.force_zero_scaling, so apps that land on XWayland
    # render at 1x unless they scale themselves. GDK_SCALE only covers GTK.
    overrides = {
      # Electron/Chromium apps (Discord): use native Wayland, scaled by the compositor
      global.Environment.ELECTRON_OZONE_PLATFORM_HINT = "auto";
      # Steam is X11-only
      "com.valvesoftware.Steam".Environment.STEAM_FORCE_DESKTOPUI_SCALING = "2";
      # Qt5 on X11 (VLC has no Wayland socket)
      "org.videolan.VLC".Environment.QT_SCALE_FACTOR = "2";
    };
  };

  # OnlyOffice disables Qt scaling and uses its own DPI checker, which only
  # honors `force-scale` in its (app-mutable) settings.xml, so patch it in place.
  home.activation.onlyofficeForceScale = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    conf="${config.home.homeDirectory}/.var/app/org.onlyoffice.desktopeditors/data/onlyoffice/desktopeditors/data/settings.xml"
    if [ ! -f "$conf" ]; then
      run ${pkgs.coreutils}/bin/install -D -m644 ${pkgs.writeText "settings.xml" "<Settings><force-scale>2</force-scale></Settings>"} "$conf"
    elif ${pkgs.gnugrep}/bin/grep -q '<force-scale>' "$conf"; then
      run ${pkgs.gnused}/bin/sed -i 's|<force-scale>[^<]*</force-scale>|<force-scale>2</force-scale>|' "$conf"
    else
      run ${pkgs.gnused}/bin/sed -i 's|</Settings>|<force-scale>2</force-scale></Settings>|' "$conf"
    fi

    # Use the system title bar: the custom one draws its own translucent
    # shadow margin around the window, which shows up as a border on Hyprland.
    conf="${config.home.homeDirectory}/.var/app/org.onlyoffice.desktopeditors/config/onlyoffice/DesktopEditors.conf"
    if [ ! -f "$conf" ]; then
      run ${pkgs.coreutils}/bin/install -D -m644 ${pkgs.writeText "DesktopEditors.conf" "[General]\ntitlebar=system\n"} "$conf"
    elif ${pkgs.gnugrep}/bin/grep -q '^titlebar=' "$conf"; then
      run ${pkgs.gnused}/bin/sed -i 's/^titlebar=.*/titlebar=system/' "$conf"
    elif ${pkgs.gnugrep}/bin/grep -q '^\[General\]' "$conf"; then
      run ${pkgs.gnused}/bin/sed -i '/^\[General\]/a titlebar=system' "$conf"
    else
      run ${pkgs.gnused}/bin/sed -i '1i [General]\ntitlebar=system' "$conf"
    fi
  '';
}
