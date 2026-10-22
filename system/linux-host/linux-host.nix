{ pkgs, config, ... }:
{
  imports = [
    ./linux-host-network.nix
  ];

  # Bootloader
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  boot.initrd.kernelModules = [
    # VFIO
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
    # GPU passthrough VM quirk
    "vendor-reset"

    # Graphics
    "amdgpu"
  ];
  
  # More GPU Passthrough VM quirk
  boot.extraModulePackages = [ config.boot.kernelPackages.vendor-reset ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:05:00.0", ATTR{reset_method}="device_specific"
  '';
  boot.extraModprobeConfig = "softdep amdgpu pre: vfio-pci";
  
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 2099999999;
    "fs.inotify.max_user_instances" = 2099999999;
    "fs.inotify.max_queued_events" = 2099999999;
  };
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids=1002:67df,1002:aaf0,1e52:b140"
    "pci=noats"
  ];

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/ead80857-c6ff-4153-9d22-f5e54b9adab1";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  fileSystems."/k8s-pv" = {
    device = "/dev/disk/by-uuid/93a12fb5-ecae-47c5-870e-9782df34c581";
    fsType = "xfs";
    options = [ "nofail" ];
  };

  # Enable docker
  virtualisation.docker.enable = true;

  # Virtual Machines
  virtualisation.spiceUSBRedirection.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
}
