{ pkgs, lib, config, naersk, mypkgs, ... }:
let
  homeDir = config.home.homeDirectory;
in
{
  programs.zsh =
    {
      enable = true;
      package = pkgs.callPackage (import ./zsh.nix) {inherit pkgs mypkgs lib;};
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
          $HOME/.krew/bin
          $GOBIN
          $path
        )

        source "${homeDir}/.shell/export.zsh"
        source "${homeDir}/.shell/alias.zsh"
        source "${homeDir}/.shell/external.zsh"
        source "${homeDir}/.shell/keybind.zsh"

        if [[ $TERM != "dumb" ]]; then
           zmodload starship
           # eval "$(starship init)"
         fi
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
        {
          name = "directory";
          file = "";
          src = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/sorin-ionescu/prezto/da87c79b3a35f5a4a504ea331e9ec52b4f786976/modules/directory/init.zsh";
            sha256 = "sha256-/RFblRzQFvXvL7f5fUftwl7x/8XJ+WSH1JxjISAM1+A=";
          };
        }
        {
          name = "pnpm-shell-completion";
          src = (import ./pnpm-shell-completion.nix) { inherit lib pkgs naersk; };
        }
      ];

      zplug = {
        enable = true;
        plugins = [
          { name = "zsh-users/zsh-autosuggestions"; }
          { name = "zsh-users/zsh-history-substring-search"; tags = [ "as:plugin" ]; }
          { name = "plugins/git"; tags = [ "from:oh-my-zsh" ]; }
          { name = "MichaelAquilina/zsh-you-should-use"; }
          { name = "wfxr/forgit"; }
          { name = "Aloxaf/fzf-tab"; }
          { name = "zsh-users/zsh-syntax-highlighting"; tags = [ "defer:2" ]; }
          { name = "greymd/docker-zsh-completion"; }
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

  home.file.".shell".source = ./shell;
  home.file."dev/bin/remote-viewer" = {
    source = ./dev/bin/remote-viewer;
    executable = true;
  };
}
