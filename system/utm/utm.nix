{ pkgs, lib, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_16;
  # boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linuxKernel.packages.linux_6_16.overrideAttrs(a: {
  #   dontStrip = true;
  # }));
  boot.kernelPatches = [ 
    {
      name = "qemu-gdb-debug-conf";
      patch = null;
      structuredExtraConfig = {
        DEBUG_INFO = lib.kernel.yes;
        DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT = lib.kernel.yes;
        KALLSYMS = lib.kernel.yes;
        LOCKUP_DETECTOR = lib.kernel.yes;
        HARDLOCKUP_DETECTOR = lib.kernel.yes;
      };
    } 
  ];
  boot.kernelParams = [ "nokaslr" ];

  nix = {
    distributedBuilds = true;
    settings.auto-optimise-store = true;  
    buildMachines = [ (import ../nixbuild.nix) ];
  };

  programs.ssh.extraConfig = ''
  Host eu.nixbuild.net
    PubkeyAcceptedKeyTypes ssh-ed25519
    ServerAliveInterval 60
    IPQoS throughput
    IdentityFile /root/.ssh/id_ed25519
  '';

  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };

  # services.xserver.enable = true;
  # services.desktopManager.plasma6.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # services.spice-vdagentd.enable = true;
  # services.spice-webdavd.enable = true;
  services.qemuGuest.enable = true;
}
