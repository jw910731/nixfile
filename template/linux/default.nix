{ pkgs, ... }:
{
  imports = [
    ../nix-cache.nix
  ];
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "zh_TW.UTF-8/UTF-8"
  ];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Nix settings
  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.lix;

    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "@wheel"
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
  };

  # Some minimal needed packages
  environment.systemPackages = with pkgs; [
    git
    vim
    joe
    zsh
    man-pages
    man-pages-posix
    strace
    gcc
    gnumake
    tmux
    killall
  ];

  # basic open ssh 
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.StreamLocalBindUnlink = "yes";
  };

  # seen as mandatory config
  documentation.dev.enable = true;
  programs.dconf.enable = true;
  fonts.fontDir.enable = true;

  # Make vscode server runnable
  programs.nix-ld.enable = true;

  # 1password cli
  programs._1password.enable = true;

  # Enable zsh
  programs.zsh.enable = true;
  environment.pathsToLink = [ "/share/zsh" ];
}
