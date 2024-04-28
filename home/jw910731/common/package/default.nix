{ pkgs, ... }:
rec {
  imports = [
    ./git.nix
    (import ./zsh { inherit home pkgs; })
  ];

  home.packages = with pkgs;[
    emacs-nox
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
    nixpkgs-fmt
    zsh-completions
    zsh-fast-syntax-highlighting
    curl
    go
    htop
    tcping-go
  ];
}
