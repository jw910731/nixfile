{...}:
{
  programs.git = {
    enable = true;
    userName = "jw910731";
    userEmail = "jw910731@gmail.com";

    aliases = {
      # add
      a = "add";

      # branch
      recent-branches = "!git for-each-ref --count=15 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
      br = "branch -v";

      # commit
      c = "commit";
      amend = "commit --amend";

      # checkout
      ck = "checkout";
      nbr = "checkout -b";

      # diff
      d = "diff";
      dc = "diff --cached";
      last = "diff HEAD^";

      # log
      l="log --graph --date=short";
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
      spush = "stash push";
      spop = "stash pop";
      sl = "stash list";

      # status
      s = "status";
      st = "status";
      stat = "status";
    };
  };
}