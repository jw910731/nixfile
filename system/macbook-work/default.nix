{ pkgs, lib, ... }:
{
  imports = [
    ./system-package.nix
    ./app.nix
    ../mac-common.nix
  ];
  system.primaryUser = "jw910731";
}
