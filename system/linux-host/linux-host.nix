{ config, pkgs, ... }:
{
  imports = [
    ./linux-host-network.nix
  ];

  nixpkgs.overlays = [
    (import ./rke2.nix)
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  boot.extraModulePackages = [ config.boot.kernelPackages.amdgpu-pro ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 2099999999;
    "fs.inotify.max_user_instances" = 2099999999;
    "fs.inotify.max_queued_events" = 2099999999;
  };

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

  # Set your time zone.
  time.timeZone = "Asia/Taipei";

  # RKE2
  environment.systemPackages = with pkgs; [
    rke2
    openiscsi
  ];

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:f471e56c1026";
  };

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  systemd.services = {
    "rke2-server" = {
      enable = true;
      path = [ pkgs.mount pkgs.iptables pkgs.umount ];
      description = "Rancher Kubernetes Engine v2 (server)";
      documentation = [ "https://github.com/rancher/rke2" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      conflicts = [ "rke2-agent.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "notify";
        EnvironmentFile = [ "-/etc/default/%N" "-/etc/sysconfig/%N" "-/usr/local/lib/systemd/system/%N.env" ];
        KillMode = "process";
        Delegate = "yes";
        LimitNOFILE = 1048576;
        LimitNPROC = "infinity";
        LimitCORE = "infinity";
        TasksMax = "infinity";
        TimeoutStartSec = 0;
        Restart = "always";
        RestartSec = "5s";
        ExecStartPre = [ "/bin/sh -xc '! /usr/bin/systemctl is-enabled --quiet nm-cloud-setup.service'" "-/sbin/modprobe br_netfilter" "-/sbin/modprobe overlay" ];
        ExecStart = [ "${pkgs.rke2.outPath}/bin/rke2 server" ];
        ExecStopPost = [ "-/bin/sh -c \"systemd-cgls /system.slice/%n | grep -Eo '[0-9]+ (containerd|kubelet)' | awk '{print $1}' | xargs -r kill\"" ];
      };
    };
  };

  environment.etc = {
    "rancher/rke2/config.yaml" = {
      text = ''
        kubelet-arg:
          - "max-pods=256"
        kube-apiserver-arg:
          - "oidc-issuer-url=https://auth.h.jw910731.dev/realms/master"
          - "oidc-client-id=kubernetes"
          - "oidc-username-claim=preferred_username"
          - "oidc-username-prefix=-"
          - "oidc-groups-claim=groups"
          - "oidc-groups-prefix="
        tls-san:
          - "home.jw910731.dev"
      '';
    };
  };

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
  documentation.dev.enable = true;

  programs.dconf.enable = true;

  # Disable CUPS for print documents.
  services.printing.enable = false;

  # # Enable flatpak
  # services.flatpak.enable = true;
  fonts.fontDir.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  # Enable sound with pipewire.
  # sound.enable = true;
  # hardware.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  #   # If you want to use JACK applications, uncomment this
  #   #jack.enable = true;

  #   # use the example session manager (no others are packaged yet so this is enabled by default,
  #   # no need to redefine it in your config for now)
  #   #media-session.enable = true;
  # };

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
