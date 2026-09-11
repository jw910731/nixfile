{ ... }:
{
  imports = [
    ./linux-host.nix
    ./hardware-configuration.nix
    ./user.nix
    ../../template/linux
    ../../template/linux/server.nix
  ];

  system.stateVersion = "24.05";
}
