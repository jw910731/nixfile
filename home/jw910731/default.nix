{ config, pkgs, nil, ... }:
{
  users.users.jw910731 = {
    packages = with pkgs; [
      _1password
      _1password-gui
      vscode
      fira-code
      nerdfonts
      nil.packages.${pkgs.system}.default
    ];
  };
}