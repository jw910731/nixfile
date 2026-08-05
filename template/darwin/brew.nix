let
  mapCask = map (x: {
    name = x;
    greedy = true;
    trusted = true;
  });
  mapTap = map (x: {
    name = x;
    trusted = true;
  });
in {
  inherit mapCask mapTap;
  options = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      extraFlags = [ "--force-cleanup" ];
    };


    brews = [
      "mole"
      "pinentry"
      "pinentry-mac"
      "pkg-config"
      "python@3.12"
    ];

    casks = mapCask [
      "1password"
      "1password-cli"
      "betterdisplay"
      "claude"
      "firefox"
      "font-hack-nerd-font"
      "ghostty"
      "helium-browser"
      "hiddenbar"
      "iina"
      "keka"
      "kekaexternalhelper"
      "orion"
      "spotify"
      "supercmd"
      "stats"
      "visual-studio-code"
      "xquartz"
      "zed"
    ];

    taps = mapTap [
      "shobhit99/tap"
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
