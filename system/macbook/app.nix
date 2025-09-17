{ mylib, ... }:
let
  brew-common = (import ../../template/darwin/brew.nix);
  mapCask = brew-common.mapCask;
  commonOptions = brew-common.options;
in
{
  homebrew = (
    mylib.recursiveMerge commonOptions {
      brews = [ ];

      casks = mapCask [
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
        "microsoft-auto-update"
        "osu"
        "readmoreading"
        "steam"
        "telegram"
      ];

      taps = [ ];

      masApps = {
        "Craft" = 1487937127;
        "LINE" = 539883307;
        "Messenger" = 1480068668;
      };
    }
  );
}
