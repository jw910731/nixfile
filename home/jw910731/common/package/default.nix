{ pkgs, config, ... }:
{
  imports = [
    ./zsh
    ./git.nix
    ./emacs.nix
    ./ghostty.nix
    ./halloy.nix
    ./tmux.nix
    ./gpg.nix
  ];

  home.packages = with pkgs; [
    fira-code
    nerd-fonts.hack
    _1password-cli
    just
    fzf
    lsd
    bat
    python3
    zip
    unzip
    dig
    jq
    krew
    zsh-completions
    zsh-fast-syntax-highlighting
    zsh-forgit
    curl
    htop
    tcping-go
    yq-go
    devenv
    nil
    nixd
    nixfmt
    nix-output-monitor
    gemini-cli
  ];

  programs.go = {
    enable = true;
    env.GOPATH = "${config.home.homeDirectory}/dev/go";
  };

  programs.direnv = {
    enable = true;
  };

  programs.nh = {
    enable = true;
  };
}
