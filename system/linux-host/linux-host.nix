{ pkgs, ... }:
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

    # Graphics
    "amdgpu"
  ];
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 2099999999;
    "fs.inotify.max_user_instances" = 2099999999;
    "fs.inotify.max_queued_events" = 2099999999;
  };
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "vfio-pci.ids==1e52:b140"
    "hugepagesz=1G"
    "hugepages=4"
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
