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
        "container"
        "virt-manager"
      ];

      casks = mapCask ([
        "android-platform-tools"
        "balenaetcher"
        "bilibili"
        "discord"
        "element"
        "font-latin-modern"
        "hhkb"
        "jetbrains-toolbox"
        "keycastr"
        "logi-options+"
        "microsoft-auto-update"
        "obs"
        "ollama-app"
        "osu"
        "prismlauncher"
        "readmoreading"
        "steam"
        "telegram"
        "utm"
        "cloudflare-warp"
      ]);

      taps = [ ];

      masApps = {
        "LINE" = 539883307;
      };
    }
  );
}
