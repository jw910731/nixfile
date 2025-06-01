{ pkgs, lib, ... }:
let
  hostname = "jw910731-MacBook-Air";
  computerName = "jw910731's Macbook Air";
in
{
  imports = [
    ./system-package.nix
    ./app.nix
    ../mac-common.nix
  ];

  # Hostname
  networking.computerName = "${computerName}";
  networking.hostName = "${hostname}";
  system.defaults.smb.NetBIOSName = "${hostname}";
  system.primaryUser = "jw910731";
}
