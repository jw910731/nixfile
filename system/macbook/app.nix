{
  # Homebrew has to be installed first.
  # This installs system-wide packages and Mac App Store apps.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
    };

    brews = [
      "borders"
      "pinentry"
      "pinentry-mac"
      "pkg-config"
      "pyenv"
      "python@3.12"
    ];

    casks = map
      (x: {
        name = x;
        greedy = true;
        args = {
          no_quarantine = true;
        };
      }) [
      "1password"
      "1password-cli"
      "aerospace"
      "aldente"
      "android-platform-tools"
      "arc"
      "balenaetcher"
      "bartender"
      "betterdisplay"
      "brave-browser"
      "discord"
      "element"
      "firefox"
      "font-latin-modern"
      "godot"
      "hhkb"
      "iina"
      "jetbrains-toolbox"
      "keka"
      "kekaexternalhelper"
      "keycastr"
      "kitty"
      "macfuse"
      "messenger"
      "microsoft-auto-update"
      "moonlight"
      "obs"
      "openinterminal"
      "orbstack"
      "playcover-nightly"
      "rapidapi"
      "raycast"
      "readmoreading"
      "stats"
      "steam"
      "telegram-desktop"
      "visual-studio-code"
      "wireshark"
      "xquartz"
      "zed"
    ];

    taps = [
      "beeftornado/rmtree"
      "homebrew/cask-versions"
      "playcover/playcover"
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];

    masApps = {
      "Craft" = 1487937127;
      "Goodnotes" = 1444383602;
      "Keynote" = 409183694;
      "LINE" = 539883307;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Slack" = 803453959;
      "Xcode" = 497799835;
      "Yoink" = 457622435;
    };
  };
}
