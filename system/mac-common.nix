{ pkgs, lib, ... }:
{
  # Hostname
  # networking.computerName = "${hostname}";
  # networking.hostName = "${hostname}";
  # system.defaults.smb.NetBIOSName = "${hostname}";

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 5;
  system.defaults = {
    LaunchServices = {
      # Disable quarantine for downloaded applications.
      LSQuarantine = false;
    };

    trackpad = {
      Clicking = true;
      Dragging = true;
      FirstClickThreshold = 0;
      SecondClickThreshold = 1;
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
  };

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  nix.configureBuildUsers = true;

  nix.settings = {
    # https://github.com/NixOS/nix/issues/7273
    auto-optimise-store = false;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    extra-platforms = lib.mkIf (pkgs.system == "aarch64-darwin") [ "x86_64-darwin" "aarch64-darwin" ];

    # Recommended when using `direnv` etc.
    keep-derivations = true;
    keep-outputs = true;
  };

  security.pam.enableSudoTouchIdAuth = true;

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

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
}
