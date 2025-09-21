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
      "pipx"
    ];

    casks = [
      "1password"
      "1password-cli"
      "aldente"
      "betterdisplay"
      "brave-browser"
      "claude"
      "firefox"
      "font-hack-nerd-font"
      "ghostty"
      "iina"
      "jordanbaird-ice@beta"
      "keka"
      "kekaexternalhelper"
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
