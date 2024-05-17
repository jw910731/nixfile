{
  # Homebrew has to be installed first.
  # This installs system-wide packages and Mac App Store apps.
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };

    brews = [
      "pinentry"
      "pinentry-mac"
      "pkg-config"
      "pyenv"
      "python@3.12"
      "joe"
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
      "aldente"
      "android-platform-tools"
      "anytype"
      "arc"
      "balenaetcher"
      "bartender"
      "betterdisplay"
      "brave-browser"
      "cloudflare-warp"
      "devpod"
      "discord"
      "element"
      "firefox"
      "font-fira-code"
      "font-hack-nerd-font"
      "font-latin-modern"
      "heptabase"
      "iina"
      "iterm2"
      "jetbrains-toolbox"
      "keka"
      "kekaexternalhelper"
      "keycastr"
      "macfuse"
      "messenger"
      "microsoft-auto-update"
      "microsoft-teams"
      "moonlight"
      "obs"
      "openinterminal"
      "orbstack"
      "playcover-nightly"
      "rapidapi"
      "raycast"
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
      "cloudflare/cloudflare"
      "homebrew/cask-versions"
      "playcover/playcover"
    ];

    masApps = {
      "Craft" = 1487937127;
      # "GarageBand" = 682658836;
      "Goodnotes" = 1444383602;
      # "iMovie" = 408981434;
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
