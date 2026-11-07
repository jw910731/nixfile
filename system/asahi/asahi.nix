{ inputs, ... }:
{
  networking.hostName = "jw910731-macbook-air";

  # nixos-apple-silicon tracks nixos-unstable; pull packages missing from the stable channel.
  nixpkgs.overlays = [
    (final: prev: {
      inherit (inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system})
        avd-fw
        asahi-va-driver
        ;
    })
    (final: prev: {
      hyprland = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.hyprland;
    })
  ];

  hardware.asahi.enable = true;
  # Peripheral firmware (Wi-Fi, webcam, ...) is extracted from the ESP at boot.
  # To pin it in the store instead, copy `vendorfw/firmware.cpio` from the ESP
  # into ./firmware and set:
  # hardware.asahi.peripheralFirmwareDirectory = ./firmware;

  # m1n1/U-Boot owns the boot chain; EFI variables are not writable.
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.systemd-boot.configurationLimit = 4;
  # kdump is not supported by the Asahi kernel.
  boot.crashDump.enable = false;
  boot.zswap.enable = true;
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];
}
