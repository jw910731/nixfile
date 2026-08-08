{ config, pkgs, ... }:
{
  imports = [
    ./framework-network.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  # boot.extraModulePackages = with config.boot.kernelPackages; [ ];
  boot.initrd.kernelModules = [ ];
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.kernel.sysctl = {};
  boot.kernelParams = [ ];

  # Set your time zone.
  time.timeZone = "Asia/Taipei";

  # # Enable the X11 windowing system.
  # services.xserver = {
  #   enable = true;
  #   videoDrivers = [ "amdgpu" ];
  #   dpi = 180;

  #   # Setup the desktop environment.
  #   displayManager = {
  #       gdm = {
  #         enable = true;
  #         autoSuspend = false;
  #       };
  #       session = [
  #         {
  #           name = "home-manager";
  #           manage = "window";
  #           start = ''
  #             ${pkgs.runtimeShell} $HOME/.hm-xsession &
  #             waitPID=$!
  #           '';
  #         }
  #       ];
  #   };
  #   desktopManager.gnome.enable = true;
  #   desktopManager.xterm.enable = false;
  # };

  # Disable CUPS for print documents.
  services.printing.enable = false;

  # Enable flatpak
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # Enable docker
  # virtualisation.docker.enable = true;

  environment.systemPackages = [
    pkgs.cifs-utils
  ];

  # Enable sound with pipewire.
  # sound.enable = true;
  # hardware.pulseaudio.enable = false;
  # security.rtkit.enable = true;
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
}
