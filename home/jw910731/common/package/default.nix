{ pkgs, ... }:
{
  imports = [
    ./zsh
    ./git.nix
    ./emacs.nix
    ./kitty.nix
    ./halloy.nix
  ];

  home.packages = with pkgs; [
    fira-code
    nerd-fonts.hack
    _1password-cli
    gnupg
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
    kubectx
    kubernetes-helm
    kustomize
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
  ];

  programs.go = {
    enable = true;
    goPath = "./dev/go";
  };

  programs.direnv = {
    enable = true;
  };

  programs.nh = {
    enable = true;
  };
}
