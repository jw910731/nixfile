{ pkgs, lib, ... }:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    settings = {
      hooks = {
        Notification = [{
          matcher = "";
          hooks = [{
            type = "command";
            command = ''jq -r '.message // "Needs attention"' | xargs -I{} bash -c 'printf "\033]9;{}\033\\" > /dev/tty''\''';
          }];
        }];
      };
      enabledPlugins = let 
        plugins = [
          "clangd-lsp@claude-plugins-official"
          "rust-analyzer-lsp@claude-plugins-official"
          "starship-claude@starship-claude"
        ];
      in lib.genAttrs plugins (s: true);
      extraKnownMarketplaces = {
        starship-claude.source = {
          source = "github";
          repo = "martinemde/starship-claude";
        };
        claude-plugins-official.source = {
          source = "github";
          repo = "anthropics/claude-plugins-official";
        };
      };
      statusLine = {
        type = "command";
        padding = 0;
        command = "env STARSHIP_CMD=${lib.getBin pkgs.starship}/bin/starship ~/.claude/starship-claude";
      };
    };
  };

  # extra config files
  home.file = {
    ".claude/starship-claude" = {
      source = ./starship-claude.sh;
      executable = true;
    };
    ".claude/starship.toml".source = ./starship.toml;
  };
}
