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

        # zcompile .zshrc
        zcompare ''${HOME}/.zshrc &
      '';
      initExtraBeforeCompInit = ''
        setopt extendedglob
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path ~/.zsh/cache

        # zcompile the completion cache; siginificant speedup.
        for file in ''${HOME}/.zcomp^(*.zwc)(.); do
          zcompare ''${file}
        done
      '';
      initExtraFirst = ''
        zcompare() {
          if [[ -s ''${1} && ( ! -s ''${1}.zwc || ''${1} -nt ''${1}.zwc) ]]; then
            zcompile ''${1}
          fi
        }
        source () {
            [[ ! "$1.zwc" -nt $1 ]] || zcompile $1
            builtin source $@ 
        }

        . () {
            [[ ! "$1.zwc" -nt $1 ]] || zcompile $1
            builtin . $@
        }
      '';


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
          { name = "zsh-users/zsh-history-substring-search"; tags = [ "as:plugin" "lazy:true" ]; }
          { name = "plugins/git"; tags = [ "from:oh-my-zsh" "lazy:true" ]; }
          { name = "modules/directory"; tags = ["from:prezto" "lazy:true"]; }
          { name = "MichaelAquilina/zsh-you-should-use"; tags = [ "lazy:true" ]; }
          { name = "wfxr/forgit"; tags = [ "lazy:true" ]; }
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
