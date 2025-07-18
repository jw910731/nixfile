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
        "meetingbar"
      ];

      taps = [ ];

      masApps = {
        "Slack" = 803453959;
      };
    }
  );
}
