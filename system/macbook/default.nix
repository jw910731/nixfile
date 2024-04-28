{ pkgs, lib, ... }:
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

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  nix.configureBuildUsers = true;

  nix.settings = {
    # https://github.com/NixOS/nix/issues/7273
    auto-optimise-store = false;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    extra-platforms = lib.mkIf (pkgs.system == "aarch64-darwin") [ "x86_64-darwin" "aarch64-darwin" ];

    # Recommended when using `direnv` etc.
    keep-derivations = true;
    keep-outputs = true;
  };

  security.pam.enableSudoTouchIdAuth = true;

  # Load nix-darwin in /etc/zshrc.
  programs.zsh.enable = true;

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
}
