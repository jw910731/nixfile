{
  programs.zsh = {
    enable = true;
    shellAliases = {};
    autocd = true;
    initExtra = "";
    initExtraBeforeCompInit = "";
    initExtraFirst = "";

    plugins = [
      {
        name = "powerlevel10k-config";
        src = ./p10k;
        file = "p10k.zsh";
      }
    ];

    zplug = {
      enable = true;
      plugins = [
        { name = "zsh-users/zsh-autosuggestions"; } 
        { name = "romkatv/powerlevel10k"; tags = [ "as:theme" "depth:1" ]; } 
        { name = "zsh-users/zsh-history-substring-search"; tags = [ "as:plugin" ]; }
      ];
    };
  };

  home.file.".p10k".source = ./p10k;
}