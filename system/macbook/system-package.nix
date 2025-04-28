{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bashInteractive
    cmake
    openssh
    screen
    zsh
    wget
  ];

  services.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
  };
}
