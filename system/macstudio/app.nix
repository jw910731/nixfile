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
        "virt-manager"
      ];

      casks = mapCask [
        "android-platform-tools"
        "balenaetcher"
        "bilibili"
        "cloudflare-warp"
        "discord"
        "element"
        "font-latin-modern"
        "hhkb"
        "keycastr"
        "openlogi"
        "obs"
        "osu"
        "prismlauncher"
        "readmoreading"
        "steam"
        "telegram"
        "utm"
      ];

      taps = mapTap [
      ];

      masApps = {
        "LINE" = 539883307;
      };
    }
  );
}
