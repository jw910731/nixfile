{ pkgs, nil, ... }:
{
  imports = [
    ./fcitx5
    ./git.nix
    ./gpg.nix
  ];

  home.packages = with pkgs;[
    vscode
    emacs
    fira-code
    nerdfonts
    brave
    (wrapOBS { plugins = [ obs-studio-plugins.obs-vaapi ]; })
    _1password
    _1password-gui
    nil.packages.${pkgs.system}.default
    noto-fonts-cjk
    pinentry-qt
    gnupg
  ];
}