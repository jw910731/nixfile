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
        "openjdk@17"
        "openjdk@21"
      ];

      casks = mapCask [
      ];

      taps = [
      ];

      masApps = {
      };
    }
  );
}
