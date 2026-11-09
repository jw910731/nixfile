{ pkgs, lib, ... }:
{
  imports = [
    ../../template/darwin
    ../../template/buildaccel/darwin-server.nix
    ./app.nix
  ];
  jw.buildAccel.server.enable = true;
}
