{ pkgs, ... }:
{
  imports = [ ./fcitx5 ];
  home.packages = with pkgs; [
    brave
    noto-fonts-cjk-sans
    vscode-fhs
  ];

  package.zed-editor.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.program = "pinentry-qt";
  };
}
