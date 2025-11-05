{ pkgs, ... }:
{
  imports = [
    ../common

    ./package/podman
    ./package/gpg.nix
  ];

  home.packages = with pkgs; [
    podman
    podman-compose
    gdb
    lldb
  ];

  home.language = {
    base = "en_US.utf-8";
    ctype = "en_US.utf-8";
    numeric = "en_US.utf-8";
    time = "en_US.utf-8";
    collate = "en_US.utf-8";
    monetary = "en_US.utf-8";
    messages = "en_US.utf-8";
    paper = "en_US.utf-8";
    name = "en_US.utf-8";
    address = "en_US.utf-8";
    telephone = "en_US.utf-8";
    measurement = "en_US.utf-8";
  };

}
