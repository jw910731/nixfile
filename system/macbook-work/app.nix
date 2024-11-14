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
      "Slack" = 803453959;
      "Yoink" = 457622435;
    };
  };
}
