{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./framework-network.nix ];

  jw.secureBoot = true;
  boot.lanzaboote = lib.mkIf config.jw.secureBoot {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    measuredBoot = {
      enable = true;
      pcrs = [
        0
        4
        7
      ];
    };
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.kernelModules = [ ];
  boot.loader.systemd-boot.configurationLimit = 8;
  boot.zswap = {
    enable = true;
  };

  services.intel-lpmd = {
    enable = true;
    config.pantherLake = true;
    mode = "ON";
  };

  jw.fingerprint = true;

  hardware.intelgpu.driver = "xe";

  environment.systemPackages = with pkgs; [ iio-sensor-proxy ];

  hardware.steam-hardware.enable = true;
}
