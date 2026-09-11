{ ... }:
{
  imports = [
    ./framework.nix
    ./luks.nix
    ./hardware-configuration.nix
    ./user.nix
    ../../template/linux
    ../../template/linux/desktop.nix
  ];

  system.stateVersion = "26.05";
}
