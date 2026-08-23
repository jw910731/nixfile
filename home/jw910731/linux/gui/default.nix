{ pkgs, ... }:
{
  imports = [
    ./fcitx5
    ./flatpak.nix
  ];
  home.packages = with pkgs; [
    helium
    noto-fonts-cjk-sans
    vscode-fhs
    spotify
    telegram-desktop
    vlc
  ];

  programs.zed-editor.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.program = "pinentry-qt";
  };

  programs.vicinae = {
    enable = true; # default: false
    systemd = {
      enable = true; # default: false
      autoStart = true; # default: false
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
  };
}
