{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 5;
  system.defaults = {
    LaunchServices = {
      # Disable quarantine for downloaded applications.
      LSQuarantine = false;
    };

    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        # No .DS_Store
        DSDontWriteUSBStores = 1;
        DSDontWriteNetworkStores = 1;
      };
      "com.apple.Music" = {
        userWantsPlaybackNotifications = 0;
        losslessEnabled = 1;
        optimizeSongVolume = 0;
        preferredDownloadAudioQuality = 15;
        preferredStreamPlaybackAudioQuality = 20;
      };
    };

    dock = {
      # Disable mission control animation
      expose-animation-duration = 0.0;
      # Set dock detail
      autohide = true;
      autohide-time-modifier = 0.25;
      autohide-delay = 0.24;
      orientation = "left";
      show-recents = false;
      # Set dock magnification
      magnification = true;
      tilesize = 40;
      largesize = 64;
      # Disable hot corner
      wvous-tl-corner = 1;
      wvous-bl-corner = 1;
      wvous-tr-corner = 1;
      wvous-br-corner = 1;

      mru-spaces = false;

      # persistent-apps = [];
    };

    screencapture = {
      disable-shadow = true;
      target = "preview";
    };

    trackpad = {
      Clicking = true;
      Dragging = true;
      FirstClickThreshold = 0;
      SecondClickThreshold = 1;
      TrackpadRightClick = true;
    };

    loginwindow = {
      LoginwindowText = "可以色色";
    };

    finder = {
      # Always show file extensions
      "AppleShowAllExtensions" = true;

      # Show status bar at bottom of finder windows with item/disk space stats
      "ShowStatusBar" = true;

      # Show path breadcrumbs in finder windows
      "ShowPathbar" = true;

      # Show the full POSIX filepath in the window title
      "_FXShowPosixPathInTitle" = true;

      # When performing a search, search the current folder by default
      "FXDefaultSearchScope" = "SCcf";

      # Disable the warning when changing a file extension
      "FXEnableExtensionChangeWarning" = false;

      # Use list view in all Finder windows by default
      "FXPreferredViewStyle" = "Nlsv";
    };

    hitoolbox.AppleFnUsageType = "Change Input Source";

  };

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  nix.settings = {
    # https://github.com/NixOS/nix/issues/7273
    auto-optimise-store = false;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    extra-platforms = lib.mkIf (pkgs.system == "aarch64-darwin") [
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    # Recommended when using `direnv` etc.
    keep-derivations = true;
    keep-outputs = true;
    trusted-users = [
      "@admin"
    ];
  };
  nix.package = pkgs.lix;

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    watchIdAuth = true;
  };

  # Load nix-darwin in /etc/zshrc.
  programs.zsh = {
    enable = true;
    interactiveShellInit = ''
      # This config is very dangerous
      # Do not change order if you don't know what you are doing
      path=(
        $path
        /opt/homebrew/bin
      )

      fpath+=/opt/homebrew/share/zsh/site-functions
    '';
  };
}
