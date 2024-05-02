{ pkgs, ... }:
{
  programs.zsh = {
    plugins = [
      {
        name = "auto-notify";
        src = pkgs.fetchFromGitHub {
          owner = "MichaelAquilina";
          repo = "zsh-auto-notify";
          rev = "22b2c61ed18514b4002acc626d7f19aa7cb2e34c";
          sha256 = "sha256-x+6UPghRB64nxuhJcBaPQ1kPhsDx3HJv0TLJT5rjZpA=";
        };
      }
      {
        name = "iterm2-integration";
        file = "";
        src = pkgs.fetchurl {
          name = "iterm2_shell_integration.zsh";
          url = "https://iterm2.com/shell_integration/zsh";
          sha256 = "sha256-Cq8winA/tcnnVblDTW2n1k/olN3DONEfXrzYNkufZvY=";
        };
      }
    ];
    # zprof.enable = true;
  };
}
