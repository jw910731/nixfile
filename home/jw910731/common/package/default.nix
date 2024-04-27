{ pkgs, ... }:
{
  imports = [
    ./git.nix
    ./gpg.nix
    ./zsh
  ];

  home.packages = with pkgs;[
    vscode
    emacs
    fira-code
    nerdfonts
    _1password
    _1password-gui
    gnupg
    just
    telegram-desktop
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
  ];
}
