{
  # Homebrew has to be installed first.
  # This installs system-wide packages and Mac App Store apps.
  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";

    brews = [
      "pinentry"
      "pinentry-mac"
      "pkg-config"
      "pyenv"
      "python@3.12"
      "joe"
    ];

    casks = [
      "1password"
      "appcleaner"
      "arc"
      "cloudflare-warp"
      "devtoys"
      "font-hack-nerd-font"
      "google-cloud-sdk"
      "heptabase"
      "iina"
      "iterm2"
      "jetbrains-toolbox"
      "logi-options-plus"
      "openinterminal"
      "openvpn-connect"
      "orbstack"
      "rapidapi"
      "raycast"
      "slack"
      "stats"
      "visual-studio-code"
      "warp"
      "zed"
    ];

    taps = [
      "homebrew/cask-fonts"
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
