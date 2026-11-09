{ pkgs, lib, ... }:
{
  imports = [
    ../../template/darwin/system-package.nix
    ./app.nix
    ../../template/darwin/mac-common.nix
  ];
}
