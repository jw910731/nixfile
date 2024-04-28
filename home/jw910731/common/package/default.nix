{ pkgs, extra, ... }:
rec {
  imports = [
    ./git.nix
    ./zsh
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
    htop
    tcping-go
    rustup
    nodePackages.pnpm
  ];

  programs.go = {
    enable = true;
    goPath = "./dev/go";
  };
}
