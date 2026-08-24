{ inputs, pkgs, ... }:
{
  imports = [
    ./fcitx5
    ./flatpak.nix
  ];
  home.packages = with pkgs; [
    noto-fonts-cjk-sans
    vscode-fhs
    spotify
    telegram-desktop
    vlc
    pulseaudio
  ];

  programs.zed-editor.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.program = "pinentry-qt";
  };

  programs.helium = {
    enable = true;
    # Optional: override the package
    # package = pkgs.helium;
    # Flags - Command-line arguments always passed to Helium
    flags = [
      "--password-store=kwallet6"
    ];
    # Optional: user policies (best-effort, use NixOS module for critical policies)
    policies = {};
  };

  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
    enableSoulver = true;
    settings = {
      close_on_focus_loss = true;
      consider_preedit = true;
      pop_to_root_on_close = true;
      favicon_service = "twenty";
      search_files_in_root = false;
      keybinding = "emacs";
      compact_mode.enabled = true;
      favorites = [
        "clipboard:history"
      ];
      fallbacks = [
        "shortcuts:sct-2bf4a48c847a"
        "@AdityaZxxx/vicinae-extension-helium-0:search-web"
      ];
      font = {
        normal = {
          size = 13;
          family = "Noto Sans CJK";
        };
      };
      theme = {
        light = {
          name = "vicinae-light";
          icon_theme = "default";
        };
        dark = {
          name = "one-dark";
          icon_theme = "default";
        };
      };
      launcher_window = {
        opacity = 0.97;
      };
    };
    extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
      nix
      power-profile
      pulseaudio
      helium
      hypr
      hypr-keybinds
      hyprland-monitors
      zed-recents
    ];
  };
}
