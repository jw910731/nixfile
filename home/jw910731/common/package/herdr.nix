{
  pkgs,
  inputs,
  config,
  ...
}:
let
  llm-agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  herdrIntegrations = "${llm-agents.herdr}/share/herdr/integrations";

  # OmO extension that renders workflow DAGs in a Herdr side pane.
  # Mirrors the layout produced by upstream's scripts/install.mjs.
  omo-herdr-dag = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "omo-herdr-dag";
    version = "1.7.0";
    src = pkgs.fetchFromGitHub {
      owner = "jc01rho";
      repo = "omo-herdr-dag";
      rev = "v${version}";
      hash = "sha256-pGHXtROZdx3668FOXqumqt76xYxgYQcFxQMsB1R4Y6E=";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r src extension.mjs LICENSE $out/
      echo '{"language":"en"}' > $out/locale.json
    '';
  };
in
{
  home.packages = [ llm-agents.herdr ];

  # Read-only (store symlink): changes made from herdr's settings UI will not persist.
  xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
    onboarding = false;

    # Mirrors tmux.nix `mouse = true`.
    ui.mouse_capture = true;

    theme.name = "one-dark";

    # tmux default keymap (see tmux.nix: stock bindings, base-index 1).
    # tmux sessions/windows/panes map to herdr workspaces/tabs/panes.
    keys = {
      prefix = "ctrl+b";
      help = "prefix+?";
      detach = "prefix+d";

      # Sessions
      workspace_picker = "prefix+s"; # choose-tree -s
      rename_workspace = "prefix+$";
      previous_workspace = "prefix+(";
      next_workspace = "prefix+)";

      # Windows
      goto = "prefix+w"; # choose-tree -w
      new_tab = "prefix+c";
      rename_tab = "prefix+,";
      previous_tab = "prefix+p";
      next_tab = "prefix+n";
      switch_tab = "prefix+1..9";
      close_tab = "prefix+&";

      # Panes
      split_vertical = "prefix+%"; # side by side
      split_horizontal = "prefix+\""; # stacked
      focus_pane_left = "prefix+left";
      focus_pane_down = "prefix+down";
      focus_pane_up = "prefix+up";
      focus_pane_right = "prefix+right";
      cycle_pane_next = "prefix+o";
      cycle_pane_previous = "";
      last_pane = "prefix+;";
      close_pane = "prefix+x";
      zoom = "prefix+z";
      resize_pane_left = [
        "prefix+ctrl+left"
        "prefix+alt+left"
      ];
      resize_pane_down = [
        "prefix+ctrl+down"
        "prefix+alt+down"
      ];
      resize_pane_up = [
        "prefix+ctrl+up"
        "prefix+alt+up"
      ];
      resize_pane_right = [
        "prefix+ctrl+right"
        "prefix+alt+right"
      ];

      # herdr-only actions whose default keys collide with tmux bindings
      settings = "prefix+shift+s";
      open_notification_target = "prefix+shift+o";
    };
  };

  # Entry point discovered by OmO; imports the extension from the store by absolute path.
  home.file.".omo/agent/extensions/omo-herdr-dag.js".text = ''
    export { default } from '${omo-herdr-dag}/extension.mjs';
  '';

  # Agent integrations, laid out like `herdr integration install <agent>` so
  # `herdr integration status` reports them current. omo needs none: Senpi ships
  # a built-in herdr reporter.

  # Claude Code
  home.file.".claude/hooks/herdr-agent-state.sh".source =
    "${herdrIntegrations}/claude/herdr-agent-state.sh";
  programs.claude-code.settings.hooks.SessionStart = [
    {
      matcher = "^(startup|resume|clear|compact|fork)$";
      hooks = [
        {
          type = "command";
          command = "bash '${config.home.homeDirectory}/.claude/hooks/herdr-agent-state.sh' session";
          timeout = 10;
        }
      ];
    }
  ];

  # OpenCode; tui.jsonc is merged with the hand-managed tui.json.
  xdg.configFile."opencode/plugins/herdr-agent-state.js".source =
    "${herdrIntegrations}/opencode/herdr-agent-state.js";
  xdg.configFile."opencode/herdr-tui-session.js".source =
    "${herdrIntegrations}/opencode/herdr-tui-session.js";
  xdg.configFile."opencode/tui.jsonc".text = builtins.toJSON {
    plugin = [ "./herdr-tui-session.js" ];
  };

  # Codex; its hooks feature is enabled by default, so config.toml is left alone.
  home.file.".codex/herdr-agent-state.sh".source = "${herdrIntegrations}/codex/herdr-agent-state.sh";
  home.file.".codex/hooks.json" = {
    text = builtins.toJSON {
      hooks.SessionStart = [
        {
          hooks = [
            {
              type = "command";
              command = "bash '${config.home.homeDirectory}/.codex/herdr-agent-state.sh' session";
              timeout = 10;
            }
          ];
        }
      ];
    };
  };
}
