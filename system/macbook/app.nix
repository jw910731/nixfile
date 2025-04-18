{
  # Homebrew has to be installed first.
  # This installs system-wide packages and Mac App Store apps.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
    };

    brews = [
      "pinentry"
      "pinentry-mac"
      "pkg-config"
      "python@3.12"
    ];

    casks =
      map
        (x: {
          name = x;
          greedy = true;
          args = {
            no_quarantine = true;
          };
        })
        [
          "1password"
          "1password-cli"
          "aldente"
          "android-platform-tools"
          "balenaetcher"
          "bartender"
          "betterdisplay"
          "brave-browser"
          "cap"
          "discord"
          "element"
          "firefox"
          "font-latin-modern"
          "hhkb"
          "iina"
          "jetbrains-toolbox"
          "karabiner-elements"
          "keka"
          "kekaexternalhelper"
          "keycastr"
          "kitty"
          "messenger"
          "microsoft-auto-update"
          "moonlight"
          "obs"
          "openinterminal"
          "orbstack"
          "orion"
          "osu"
          "rapidapi"
          "raycast"
          "readmoreading"
          "stats"
          "steam"
          "telegram-desktop"
          "utm"
          "visual-studio-code"
          "wireshark"
          "xquartz"
          "zed"
        ];

    taps = [
      "homebrew/cask-versions"
    ];

    masApps = {
      "Craft" = 1487937127;
      "Keynote" = 409183694;
      "LINE" = 539883307;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Portal" = 1436994560;
      "Slack" = 803453959;
      "Yoink" = 457622435;
    };
  };
}
