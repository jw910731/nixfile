{ ... }:
{
  programs.opencode = {
    enable = true;
    settings = {
      model = "zai-coding-plan/glm-5";
      small_model = "zai-coding-plan/glm-4.7-flash";
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
    };
  };  
}
