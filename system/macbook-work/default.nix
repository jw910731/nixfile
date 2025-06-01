{ pkgs, lib, ... }:
let
  hostname = "jerrywu-macbook";
in
{
  imports = [
    ./system-package.nix
    ./app.nix
    ../mac-common.nix
  ];

  # Hostname
  networking.computerName = "${hostname}";
  networking.hostName = "${hostname}";
  system.defaults.smb.NetBIOSName = "${hostname}";
  system.primaryUser = "jw910731";
}
