{ mylib, ... }:
let
  brew-common = (import ../../template/darwin/brew.nix);
  mapCask = brew-common.mapCask;
  commonOptions = brew-common.options;
in
{
  homebrew = (
    mylib.recursiveMerge commonOptions {
      brews = [
        "blacktop/tap/ipsw"
      ];

      casks = mapCask (
        [
          "android-platform-tools"
          "balenaetcher"
          "bilibili"
          "container"
          "discord"
          "element"
          "font-latin-modern"
          "hhkb"
          "jetbrains-toolbox"
          "keycastr"
          "logi-options+"
          "microsoft-auto-update"
          "obs"
          "osu"
          "prismlauncher"
          "readmoreading"
          "steam"
          "telegram"
          "utm"
        ]
        ++ [
          "meetingbar"
          "microsoft-teams"
          "openvpn-connect"
        ]
      );

      taps = [ ];

      masApps = {
        "Craft" = 1487937127;
        "LINE" = 539883307;
        "Messenger" = 1480068668;
      };
    }
  );
}
