{ pkgs, ... }:
{
  imports = [
    ./zsh
    ./git.nix
    ./emacs.nix
  ];

  home.packages = with pkgs;[
    fira-code
    nerdfonts
    _1password
    gnupg
    just
    fzf
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
    k9s
    yq-go
    poetry
  ];

  programs.go = {
    enable = true;
    goPath = "./dev/go";
  };
}
