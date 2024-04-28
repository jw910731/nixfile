{ pkgs, ... }:
{
  programs.zsh = {
    plugin = [
      {
        name = "auto-notify";
        src = pkgs.fetchFromGitHub {
          owner = "MichaelAquilina";
          repo = "zsh-auto-notify";
          rev = "22b2c61ed18514b4002acc626d7f19aa7cb2e34c";
          sha256 = "sha256-x+6UPghRB64nxuhJcBaPQ1kPhsDx3HJv0TLJT5rjZpA=";
        };
      }
    ];
    # zprof.enable = true;
  };
}
