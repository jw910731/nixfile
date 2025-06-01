{ pkgs, ... }:

{
  security.pki.installCACerts = false;

  environment.systemPackages = with pkgs; [
    bashInteractive
    cmake
    openssh
    screen
    zsh
    wget
  ];

  services.emacs = {
    package = pkgs.emacs-nox;
  };
}
