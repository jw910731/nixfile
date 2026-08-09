{ pkgs, ... }:
{
  boot.initrd = {
    luks.devices.root = {
      crypttabExtraOpts = [
        "fido2-device=auto"
        "tpm2-device=auto"
      ];
      device = "/dev/nvme0n1p2";
      preLVM = true;
      bypassWorkqueues = true;
      allowDiscards = true;
    };
    availableKernelModules = [
      "aesni_intel"
      "cryptd"
    ];
  };
}
