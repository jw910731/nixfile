{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bashInteractive
    cmake
    openssh
    screen
    zsh
    wget
  ];

  services.emacs = {
    # Patch emacs on darwin, see https://github.com/NixOS/nixpkgs/issues/395169
    package = pkgs.emacs-nox.override { withNativeCompilation = false; };
  };
}
