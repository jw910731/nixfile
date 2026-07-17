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
        "container"
        "virt-manager"
      ];

      casks = mapCask ([
        "android-platform-tools"
        "balenaetcher"
        "bilibili"
        "cloudflare-warp"
        "discord"
        "element"
        "font-latin-modern"
        "hhkb"
        "keycastr"
        "logi-options+"
        "obs"
        "osu"
        "prismlauncher"
        "readmoreading"
        "steam"
        "telegram"
        "utm"
      ]);

      taps = [
      ];

      masApps = {
        "LINE" = 539883307;
      };
    }
  );
}
