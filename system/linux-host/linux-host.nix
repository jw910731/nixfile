{ config, pkgs, ... }:
{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.loader.systemd-boot.configurationLimit = 10;

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/ead80857-c6ff-4153-9d22-f5e54b9adab1";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  
  networking.hostName = "jw910731-nixos"; # Define your hostname.
  networking.interfaces.enp6s0 = {
    wakeOnLan = {
      enable = true;
      policy = ["magic"];
    };
    useDHCP = true;
  };

  # networking.nftables.enable = true;
  networking.firewall.enable = false;

  # Set your time zone.
  time.timeZone = "Asia/Taipei";
  
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    dpi = 180;

    # Setup the desktop environment.
    displayManager = {
        gdm = {
          enable = true;
          autoSuspend = false;
        };
        session = [
          {
            name = "home-manager";
            manage = "window";
            start = ''
              ${pkgs.runtimeShell} $HOME/.hm-xsession &
              waitPID=$!
            '';
          }
        ];
    };
    desktopManager.gnome.enable = true;
    desktopManager.xterm.enable = false;
  };
  documentation.dev.enable = true;

  programs.dconf.enable = true;

  # Disable CUPS for print documents.
  services.printing.enable = false;

  # Enable flatpak
  services.flatpak.enable = true;
  fonts.fontDir.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # nix config
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  nix.settings.auto-optimise-store = true;
}
