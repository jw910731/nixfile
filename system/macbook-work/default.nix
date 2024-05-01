{ pkgs, lib, ... }:
{
  imports = [
    ./system-package.nix
    ./app.nix
    ../mac-common.nix
  ];

  # Hostname
  # networking.computerName = "${hostname}";
  # networking.hostName = "${hostname}";
  # system.defaults.smb.NetBIOSName = "${hostname}";
}
