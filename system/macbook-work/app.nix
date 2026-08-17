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
      brews = [ ];

      casks = mapCask [
        "openlogi"
        "meetingbar"
        "microsoft-teams"
        "openvpn-connect"
      ];

      taps = mapTap [ ];

      masApps = {
      };
    }
  );
}
