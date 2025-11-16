{ pkgs, ... }:
{
  imports = [ ./fcitx5 ];
  home.packages = with pkgs; [
    brave
    noto-fonts-cjk-sans
    vscode-fhs
  ];
}
