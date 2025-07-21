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

      casks = [
        "android-platform-tools"
        "balenaetcher"
        "container"
        "element"
        "font-latin-modern"
        "hhkb"
        "jetbrains-toolbox"
        "keycastr"
        "kitty"
        "lm-studio"
        "logi-options+"
        "microsoft-auto-update"
        "obs"
        "osu"
        "prismlauncher"
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
