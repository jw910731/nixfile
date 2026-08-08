{ pkgs, ... }:
{
  imports = [ ./fcitx5 ];
  home.packages = with pkgs; [
    helium
    noto-fonts-cjk-sans
    vscode-fhs
  ];

  programs.zed-editor.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.program = "pinentry-qt";
  };
}
