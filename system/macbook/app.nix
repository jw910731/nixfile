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
      "dash"
      "discord"
      "element"
      "firefox"
      "font-latin-modern"
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
      "homebrew/cask-versions"
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];

    masApps = {
      "Craft" = 1487937127;
      "Keynote" = 409183694;
      "LINE" = 539883307;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Slack" = 803453959;
      "Yoink" = 457622435;
    };
  };
}
