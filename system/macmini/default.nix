{ pkgs, lib, ... }:
{
  imports = [
    ../../template/darwin
    ./app.nix
  ];
}
