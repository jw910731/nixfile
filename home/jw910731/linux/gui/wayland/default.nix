{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    wl-clipboard
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    plugins = with pkgs.hyprlandPlugins; [
      # Since package is broken, it is disable until it get fiexed
      # hyprgrass
    ];
    configType = "lua";
    settings = {
      pam_init = {
        _var = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
      };
      grim = {
        _var = "${lib.getBin pkgs.grim}/bin/grim";
      };
      swappy = {
        _var = "${lib.getBin pkgs.swappy}/bin/swappy";
      };
      slurp = {
        _var = "${lib.getBin pkgs.slurp}/bin/slurp";
      };
      wl_copy = {
        _var = "${lib.getBin pkgs.wl-clipboard}/bin/wl-copy";
      };
    };
    extraConfig = builtins.readFile ./hyprland.lua;
  };
  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
  xdg.configFile."uwsm/env-hyprland".text = ''
    export LANG="zh_TW.utf-8"builtins.readFile ./hyprland.lua
    export LC_ADDRESS="zh_TW.utf-8"
    export LC_COLLATE="zh_TW.utf-8"
    export LC_CTYPE="zh_TW.utf-8"
    export LC_MEASUREMENT="zh_TW.utf-8"
    export LC_MESSAGES="zh_TW.utf-8"
    export LC_MONETARY="zh_TW.utf-8"
    export LC_NAME="zh_TW.utf-8"
    export LC_NUMERIC="zh_TW.utf-8"
    export LC_PAPER="zh_TW.utf-8"
    export LC_TELEPHONE="zh_TW.utf-8"
    export LC_TIME="zh_TW.utf-8"
  '';

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  gtk = {
    enable = true;
    gtk4.theme = config.gtk.theme;
    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Blue-Dark";
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    font = {
      name = "Noto Sans CJK TC";
      size = 13;
    };
  };
  xdg.configFile."gtk-4.0/gtk.css".force = true;

  qt = {
    enable = true;
    style.name = "adwaita-dark";
    qt6ctSettings = {
      Fonts = {
        fixed = "\"Noto Sans Mono CJK TC,13\"";
        general = "\"Noto Sans CJK TC,13\"";
      };
    };
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      theme = {
        mode = "dark";
        source = "community";
        builtin = "One Dark Two";
      };
      wallpaper = {
        enabled = true;
      };
      location = {
        auto_locate = true;
      };
    };
  };
}
