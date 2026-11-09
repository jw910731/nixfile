{ pkgs, lib, ... }:
{
  imports = [
    ../../template/darwin/system-package.nix
    ./app.nix
    ../../template/darwin/mac-common.nix
  ];
  system = {
    primaryUser = "jerry.wu";
    defaults = {
      loginwindow.LoginwindowText = lib.mkForce null;
    };
  };
}
