{ pkgs, ... }:
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
    llvm
    cmake
    dig
    docker-compose
    kubectl
    kubernetes-helm
    jq
    krew
    zsh-completions
    zsh-fast-syntax-highlighting
    zsh-forgit
    curl
    htop
    tcping-go
    k9s
    yq-go
    devenv
    nil
    nixd
    nixfmt
    nix-output-monitor
    imagemagick
    claude-code
  ];

  programs.go = {
    enable = true;
    env.GOPATH = "./dev/go";
  };

  programs.direnv = {
    enable = true;
  };

  programs.nh = {
    enable = true;
  };
}
