{ pkgs, lib, ... }:
{
  imports = [
    ../../template/home-darwin/system-package.nix
    ./app.nix
    ../../template/home-darwin/mac-common.nix
  ];
  system.primaryUser = "jw910731";
}
