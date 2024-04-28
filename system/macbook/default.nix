{ pkgs, ... }:
{
  imports = [
    ./system-package.nix
    ./app.nix
  ];

  # Hostname
  # networking.computerName = "${hostname}";
  # networking.hostName = "${hostname}";
  # system.defaults.smb.NetBIOSName = "${hostname}";

  nixpkgs.config.allowUnfree = true;

  system.defaults = {
    LaunchServices = {
      # Disable quarantine for downloaded applications.
      LSQuarantine = false;
    };
  };
  security.pam.enableSudoTouchIdAuth = true;

  programs.zsh.enable = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
}
