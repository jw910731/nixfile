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
          "kitty"
          "meetingbar"
          "raycast"
          "sourcetree"
          "stats"
          "visual-studio-code"
          "zed"
        ];

    taps = [
    ];

    masApps = {
      "Portal" = 1436994560;
      "Slack" = 803453959;
      "Yoink" = 457622435;
    };
  };
}
