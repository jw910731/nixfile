{ pkgs, lib, ... }:
{
  imports = [
    ../../template/darwin
    ./app.nix
  ];
  system.primaryUser = "jw910731";
}
