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
    nerdfonts
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
    nixpkgs-fmt
    zsh-completions
    zsh-fast-syntax-highlighting
    curl
    htop
    tcping-go
    k9s
    yq-go
    poetry
    devenv
    nil
    nixd
    nixfmt-rfc-style
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
}
