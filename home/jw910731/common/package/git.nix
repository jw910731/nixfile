{...}:
{
  programs.git = {
    # Basic
    enable = true;
    userName = "jw910731";
    userEmail = "jw910731@gmail.com";

    # LFS
    lfs.enable = true;

    # Sign
    signing= {
      signByDefault = true;
      key="16D83FE3495FA263";
    };

    # Extra config
    extraConfig = {
      core = {
        editor="\"emacs -nw\"";
        autocrlf = "input";
        excludesfile = "~/.gitignore_global";
      };
      diff.tool = "vscode";
      "difftool \"vscode\"".cmd = "code --wait --diff $LOCAL $REMOTE";

      color.ui = true;
      "color \"diff-highlight\"" = {
        oldNormal = "red bold";
        oldHighlight = "white bold 52";
        newNormal = "green bold";
        newHighlight = "white bold 22";
      };

      pull.rebse = false;

      merge = {
        tool = "emacs";
        guitool = "vscode";
      };

      "mergetool \"emacs\"".cmd = "emacs -nw";
      "mergetool \"vscode\"".cmd = "code --wait $MERGED";
    };

    # Alias
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