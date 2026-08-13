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
  ];

  programs.zed-editor.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.program = "pinentry-qt";
  };
}
