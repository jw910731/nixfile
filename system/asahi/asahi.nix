{ pkgs, ... }:
{
  nix = {
    buildMachines = [
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        hostName = "ssh.jw910731.dev";
        protocol = "ssh-ng";
        maxJobs = 16;
        supportedFeatures = [ "big-parallel" ];
      }
    ];
    distributedBuilds = true;
    # Enable nix command and flakes
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    extraOptions = ''
      builders-use-substitutes = true
    '';
    # nix config
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };

    settings.auto-optimise-store = true;
  };

  # $ nix search wget
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = [ "jw910731" ];
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # man page
  documentation.dev.enable = true;

  # dconf
  programs.dconf.enable = true;

  # Disable CUPS for print documents.
  services.printing.enable = false;

  # # Enable flatpak
  # services.flatpak.enable = true;
  fonts.fontDir.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  # Emacs Daemon
  services.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
  };

  # Enable flatpak
  services.flatpak.enable = true;
}
