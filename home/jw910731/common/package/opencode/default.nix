{ pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    package = pkgs.llm-agents.opencode;
    settings = {
      model = "zai-coding-plan/glm-5.2";
      small_model = "zai-coding-plan/glm-4.7-flash";
      provider.zai-coding-plan.options.apiKey = "{file:~/.config/opencode/zai-key}";
      provider.omniroute = {
        npm = "@ai-sdk/openai-compatible";
        name = "OmniRoute";
        options = {
          baseURL = "{file:~/.config/opencode/omniroute-base}";
          apiKey = "{file:~/.config/opencode/omniroute-key}";
          modelsDiscovery = {
            enabled = true;
            endpoint = "/models";
          };
        };
      };
      mcp = {
        web-search-prime = {
          type = "remote";
          url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
          headers.Authorization = "{file:~/.config/opencode/zai-key}";
        };
      };
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
        web-search-prime_web_search_prime = "allow";
        codesearch = "allow";
        todoread = "allow";
        todowrite = "allow";
      };
    };
  };
}
