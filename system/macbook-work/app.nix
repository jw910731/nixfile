{ mylib, ... }:
let
  brew-common = (import ../../template/darwin/brew.nix);
  mapCask = brew-common.mapCask;
  mapTap = brew-common.mapTap;
  commonOptions = brew-common.options;
in
{
  homebrew = (
    mylib.recursiveMerge commonOptions {
      brews = [
        "container"
      ];

      casks = mapCask [
        "android-platform-tools"
        "cursor"
        "meetingbar"
      ];

      taps = mapTap [ ];

      masApps = {
      };
    }
  );
}
