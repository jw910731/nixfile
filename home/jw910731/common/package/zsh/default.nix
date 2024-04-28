{ pkgs, lib, ... }:
let
  homeDir = if pkgs.stdenv.isLinux then "/home/jw910731" else "/Users/jw910731";
in
{
  programs.zsh =
    {
      enable = true;
      enableCompletion = true;
      shellAliases = { };
      autocd = true;
      initExtra = ''
        path=(
          $HOME/.local/bin
          $HOME/dev/bin
          $path
        )

        source "${homeDir}/.shell/alias.zsh"
        source "${homeDir}/.shell/external.zsh"
      '';
      initExtraBeforeCompInit = "";
      initExtraFirst = ''
        # Golang env setting
        if (( $+commands[go] )); then
          export GOPATH=$HOME/dev/go
          export GOBIN=$GOPATH/bin
        fi
      '';

      plugins = [
        {
          name = "powerlevel10k-config";
          src = ./p10k;
          file = "p10k.zsh";
        }
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "f95cdcf2c390428d271f2304698c2d45f0cd4de5";
            sha256 = "sha256-plGAwdmHQQCEBqEKOZumS1vZ0AwLE7A4tUImgljK5kI=";
          };
        }
        {
          name = "forgit";
          src = pkgs.fetchFromGitHub {
            owner = "wfxr";
            repo = "forgit";
            rev = "23.06.0";
            sha256 = "sha256-HxdTRv4OFf7Bh3FnTB7FMjhizCLH5DbuOHzQq2SYfAE=";
          };
        }
        {
          name = "extract";
          src = pkgs.fetchFromGitHub {
            owner = "birkhofflee";
            repo = "zsh-plugin-extract";
            rev = "1.0.0";
            sha256 = "sha256-KjQoMGqbrjuvfy+Lf3eI32aN09sLpHjh5S/tRTnhAco=";
          };
        }
        {
          name = "you-should-use";
          src = pkgs.fetchFromGitHub {
            owner = "MichaelAquilina";
            repo = "zsh-you-should-use";
            rev = "1f9cb008076d4f2011d5f814dfbcfbece94a99e0";
            sha256 = "sha256-lKs6DhG3x/oRA5AxnRT+odCZFenpS86wPnPqxLonV2E=";
          };
        }
        {
          name = "docker-zsh-completion";
          src = pkgs.fetchFromGitHub {
            owner = "greymd";
            repo = "docker-zsh-completion";
            rev = "1f073f461caca4773ca7b4a1c13bb267ab8bd592";
            sha256 = "sha256-jEBlJmHIVuiWkCRJ6leP5apI8vjB0VbYXxY5niI0QEo=";
          };
        }
        {
          name = "gnu-utility";
          file = "";
          src = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/sorin-ionescu/prezto/8d00c51900dfce3b2bc1e5bd99bd58f238c5668a/modules/gnu-utility/init.zsh";
            sha256 = "sha256-5sx3r71NGT9DokDVwfjlKomYzIgpRwaA2Ky01QRN9sY=";
          };
        }
        {
          name = "directory";
          file = "";
          src = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/sorin-ionescu/prezto/da87c79b3a35f5a4a504ea331e9ec52b4f786976/modules/directory/init.zsh";
            sha256 = "sha256-/RFblRzQFvXvL7f5fUftwl7x/8XJ+WSH1JxjISAM1+A=";
          };
        }
      ];

      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; }
          { name = "zsh-users/zsh-history-substring-search"; tags = [ "as:plugin" ]; }
          { name = "plugins/git"; tags = [ "from:oh-my-zsh" ]; }
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
