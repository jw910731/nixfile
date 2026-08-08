{ pkgs, ... }:
{
  imports = [ ./fcitx5 ];
  home.packages = with pkgs; [
    helium
    noto-fonts-cjk-sans
    vscode-fhs
    spotify
    discord
  ];

  programs.zed-editor.enable = true;

  services.toshy.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.program = "pinentry-qt";
  };
}
