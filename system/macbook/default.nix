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

  nix = {
    linux-builder = {
      enable = true;
      ephemeral = true;
      maxJobs = 4;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 40 * 1024;
            memorySize = 8 * 1024;
          };
          cores = 6;
        };
      };
    };
    settings.trusted-users = [ "@admin" ];
  };

  # Hostname
  networking.computerName = "${computerName}";
  networking.hostName = "${hostname}";
  system.defaults.smb.NetBIOSName = "${hostname}";
}
