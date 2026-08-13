{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./framework-network.nix
  ];

  # Secure Boot & Bootloader
  boot.loader.systemd-boot.enable = false;
  boot.lanzaboote = {
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
  boot.extraModulePackages = with config.boot.kernelPackages; [ ];
  boot.initrd.kernelModules = [ ];
  boot.loader.systemd-boot.configurationLimit = 8;
  boot.kernel.sysctl = { };
  boot.kernelParams = [ ];
  boot.zswap = {
    enable = true;
  };

  # Power Management
  services.thermald.enable = true;
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  services.intel-lpmd = {
    enable = true;
    config.pantherLake = true;
    mode = "ON";
  };

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

  # Graphic Interface
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.desktopManager = {
    plasma6.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Fingerprint sensor
  services.fprintd.enable = true;
  services.acpid = {
    enable = true;
    lidEventCommands =
      let
        goodixVendor = "27c6";
      in
      ''
        grep -q closed /proc/acpi/button/lid/LID0/state
        if [ $? = 0 ]; then
          ${pkgs.fd}/bin/fd "-" /sys/bus/usb/devices --exec /bin/sh -c '${pkgs.gnugrep}/bin/grep -qs ${goodixVendor} {}/idVendor && ${pkgs.coreutils}/bin/echo 0 > {}/authorized'
        else
          ${pkgs.fd}/bin/fd "-" /sys/bus/usb/devices --exec /bin/sh -c '${pkgs.gnugrep}/bin/grep -qs ${goodixVendor} {}/idVendor && ${pkgs.coreutils}/bin/echo 1 > {}/authorized'
        fi
      '';
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
  services.blueman.enable = true;

  # Graphics
  hardware.intelgpu = {
    driver = "xe";
  };

  # Enable docker
  # virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    cifs-utils
    kdePackages.kio
    kdePackages.kio-fuse
    kdePackages.kio-extras
    iio-sensor-proxy
    sbctl
    touchegg
  ];

  # Steam
  hardware.steam-hardware.enable = true;

  # Touchpad
  services.touchegg.enable = true;

  # Enable sound with pipewire.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Bluetooth
    wireplumber = {
      enable = true;
      extraConfig."10-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
            "a2dp_sink"
            "a2dp_source"
            "bap_sink"
            "bap_source"
          ];
          "bluez5.codecs" = [
            "ldac"
            "aptx"
            "aptx_ll_duplex"
            "aptx_ll"
            "aptx_hd"
            "opus_05_pro"
            "opus_05_71"
            "opus_05_51"
            "opus_05"
            "opus_05_duplex"
            "aac"
            "sbc_xq"
          ];

          "bluez5.hfphsp-backend" = "none";
        };
      };
    };

    # Airplay
    raopOpenFirewall = true;
    extraConfig.pipewire = {
      "10-airplay" = {
        "context.modules" = [
          {
            name = "libpipewire-module-raop-discover";
          }
        ];
      };
    };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}
