{ pkgs, lib, ... }:
let
  homeDir = if pkgs.stdenv.isLinux then "/home/jw910731" else "/Users/jw910731";
in
{
  programs.zsh =
    {
      enable = true;
      enableCompletion = true;
      completionInit = ''
        autoload -Uz compinit
        for dump in ~/.zcompdump(N.mh+24); do
          compinit
        done
        compinit -C
      '';
      shellAliases = { };
      autocd = true;
      initExtra = ''
        path=(
          $HOME/.local/bin
          $HOME/dev/bin
          $GOBIN
          $path
        )

        source "${homeDir}/.shell/alias.zsh"
        source "${homeDir}/.shell/external.zsh"
        source "${homeDir}/.shell/keybind.zsh"
      '';
      initExtraBeforeCompInit = "";
      initExtraFirst = "";

      plugins = [
        {
          name = "gnu-utility";
          file = "";
          src = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/sorin-ionescu/prezto/8d00c51900dfce3b2bc1e5bd99bd58f238c5668a/modules/gnu-utility/init.zsh";
            sha256 = "sha256-5sx3r71NGT9DokDVwfjlKomYzIgpRwaA2Ky01QRN9sY=";
          };
        }
      ];      

      zplug = {
        enable = true;
        plugins = [
          { name = "~/.p10k"; tags = [ "from:local" ]; }
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; }
          { name = "zsh-users/zsh-history-substring-search"; tags = [ "as:plugin" ]; }
          { name = "plugins/git"; tags = [ "from:oh-my-zsh" ]; }
          { name = "g-plane/pnpm-shell-completion"; tags = [ "hook-build:./zplug.zsh" "defer:2" ]; }
          { name = "modules/directory"; tags = ["from:prezto"]; }
          { name = "MichaelAquilina/zsh-you-should-use"; }
          { name = "wfxr/forgit"; }
          { name = "Aloxaf/fzf-tab"; }
        ];
      };

      history = {
        extended = true;
        expireDuplicatesFirst = true;
        ignorePatterns = [ "rm * " ];
      };

      dirHashes = {
        dl = "$HOME/Downloads";
      };

    };

  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  home.file.".p10k".source = ./p10k;
  home.file.".shell".source = ./shell;
}
