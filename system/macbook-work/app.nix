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
      "aerospace"
      "appcleaner"
      "arc"
      "bartender"
      "betterdisplay"
      "cloudflare-warp"
      "dash"
      "google-cloud-sdk"
      "iina"
      "jetbrains-toolbox"
      "kitty"
      "logi-options-plus"
      "mongodb-compass"
      "openinterminal"
      "openvpn-connect"
      "orbstack"
      "rapidapi"
      "raycast"
      "stats"
      "visual-studio-code"
      "zed"
    ];

    taps = [
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];

    masApps = {
      # "GarageBand" = 682658836;
      # "iMovie" = 408981434;
      # "Keynote" = 409183694;
      # "LINE" = 539883307;
      # "Numbers" = 409203825;
      # "Pages" = 409201541;
      "Slack" = 803453959;
      # "Xcode" = 497799835;
      "Yoink" = 457622435;
    };
  };
}
