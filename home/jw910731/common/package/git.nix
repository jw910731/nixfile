{ ... }:
{
  programs.git = {
    # Basic
    enable = true;

    # LFS
    lfs.enable = true;

    # Extra config
    extraConfig = {
      # Editor
      core = {
        editor = "emacs";
        autocrlf = "input";
        excludesfile = "~/.gitignore_global";
      };

      # Diff
      diff.guitool = "vscode";
      difftool.vscode.cmd = "code --wait --diff $LOCAL $REMOTE";

      color.ui = true;
      color.diff-highlight = {
        oldNormal = "red bold";
        oldHighlight = "white bold 52";
        newNormal = "green bold";
        newHighlight = "white bold 22";
      };

      pull.rebse = "merge";

      merge = {
        tool = "emacs";
        guitool = "vscode";
      };
      mergetool = {
        emacs.cmd = "emacs";
        vscode.cmd = "code --wait $MERGED";  
      };
    };

    # Alias
    aliases = {
      # add
      a = "forgit add";

      # branch
      recent-branches = "!git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
      br = "branch -v";

      # commit
      c = "commit";
      amend = "commit --amend";

      # checkout & switch
      ck = "forgit checkout_branch";
      nbr = "switch -c";
      sw = "switch";

      # diff
      d = "forgit diff";
      dc = "diff --cached";
      last = "diff HEAD^";

      # log
      l = "log --graph --date=short";
      changes = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\" --name-status";
      short = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\"";
      simple = "log --pretty=format:\" * %s\"";

      # pull & push
      pl = "pull";
      ps = "push";

      # remote
      r = "remote -v";

      # reset
      unstage = "reset HEAD";
      uncommit = "reset --soft HEAD^";
      filelog = "log -u";
      mt = "mergetool -g";

      # stash
      spush = "forgit stash_push";
      spop = "stash pop";
      sls = "forgit stash_show";

      # status
      s = "status";
      st = "status";
      stat = "status";
    };
  };
}
