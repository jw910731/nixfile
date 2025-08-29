{ pkgs, lib, ... }:
{
  imports = [
    ../../template/darwin
    ./app.nix
  ];
  system.primaryUser = "jw910731";
  programs.zsh.enableGlobalCompInit = false;
}
