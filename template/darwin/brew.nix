{
  mapCask = map (x: {
    name = x;
    greedy = true;
    args = {
      no_quarantine = true;
    };
  });
  options = {
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

    casks = [
      "1password"
      "1password-cli"
      "aldente"
      "bartender"
      "betterdisplay"
      "brave-browser"
      "firefox"
      "iina"
      "keka"
      "kekaexternalhelper"
      "kitty"
      "raycast"
      "stats"
      "visual-studio-code"
      "xquartz"
      "zed"
    ];

    taps = [
    ];

    masApps = {
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Portal" = 1436994560;
      "Yoink" = 457622435;
    };
  };
}
