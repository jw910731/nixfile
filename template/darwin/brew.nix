{
  mapCask = map (x: {
    name = x;
    greedy = true;
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
      "betterdisplay"
      "brave-browser"
      "firefox"
      "font-hack-nerd-font"
      "ghostty"
      "iina"
      "jordanbaird-ice@beta"
      "keka"
      "kekaexternalhelper"
      "orion"
      "raycast"
      "spotify"
      "stats"
      "visual-studio-code"
      "xquartz"
      "zed"
    ];

    taps = [
    ];

    masApps = {
      "Keynote" = 361285480;
      "Numbers" = 361304891;
      "Pages" = 361309726;
      "Portal" = 1436994560;
      "reMarkable desktop" = 1276493162;
      "Yoink" = 457622435;
    };
  };
}
