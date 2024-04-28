{ pkgs, ... }:
{
  imports = [
    ./git.nix
    ./zsh
  ];

  home.packages = with pkgs;[
    emacs
    fira-code
    nerdfonts
    _1password
    gnupg
    just
    fzf
    most
    lsd
    bat
    python3
    zip
    unzip
    clang
    llvm
    cmake
    dig
    nil
    docker-compose
    kubectl
    kubectx
    kubernetes-helm
    kustomize
    jq
    krew
    nixfmt
  ];
}
