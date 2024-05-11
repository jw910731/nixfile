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

  nixpkgs.config.permittedInsecurePackages = [
    "vault-1.14.10"
  ];
}
