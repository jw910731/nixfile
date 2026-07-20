{ pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    package = pkgs.llm-agents.opencode;
    settings = {
      plugin = [
        "oh-my-openagent@latest"
        "opencode-models-discovery@latest"
      ];
      permission = {
        "*" = "ask";
        bash = {
          "*" = "ask";
          "ls *" = "allow";
          "echo *" = "allow";
          "cat *" = "allow";
          "head *" = "allow";
          "tail *" = "allow";
          "find *" = "allow";
          "cd *" = "allow";
          "grep *" = "allow";
          "ps *" = "allow";
          "wc *" = "allow";
          "sort *" = "allow";
          "xargs ls *" = "allow";
          "xargs echo *" = "allow";
          "xargs cat *" = "allow";
          "xargs head *" = "allow";
          "xargs tail *" = "allow";
          "xargs grep *" = "allow";
          "xargs ps *" = "allow";
          "xargs wc *" = "allow";
          "xargs sort *" = "allow";
          "git status *" = "allow";
          "git diff *" = "allow";
          "git log *" = "allow";
          "git remote -v" = "allow";
          "pip list *" = "allow";
          "pip show *" = "allow";
          "nm *" = "allow";
          "objdump *" = "allow";
          "sleep *" = "deny";
        };
        task = "allow";
        lsp = "allow";
        read = "allow";
        glob = "allow";
        grep = "allow";
        webfetch = "allow";
        websearch = "allow";
        codesearch = "allow";
        todoread = "allow";
        todowrite = "allow";
      };
      mcp = {
        ida-pro-mcp = {
          type = "remote";
          url = "http://127.0.0.1:13337/mcp";
        };
      };
    };
  };
}
