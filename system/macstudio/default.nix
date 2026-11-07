{ pkgs, lib, ... }:
{
  imports = [
    ../../template/darwin
    ../../template/buildaccel/darwin-server.nix
    ./app.nix
  ];
  system.primaryUser = "jw910731";
  jw.buildAccel.server.enable = true;
}
