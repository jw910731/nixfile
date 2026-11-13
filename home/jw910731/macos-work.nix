{
  lib,
  pkgs,
  config,
  ...
}:
let
  username = "jerry.wu";
in {
  imports = [
    ./common

    ./darwin
  ];
  home = {
    inherit username;
    homeDirectory = lib.mkForce "/Users/${username}";
  };

  programs.git = {
    # Sign
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/T8ZSm/GVIb0a6772yGIhXlMGVcaDO5DTsOsboT/Jp";
    };
    settings = {
      gpg = {
        format = "ssh";
        ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
      user = {
        name = "Jerry Wu";
        email = "jerry.wu@samba.tv";
      };
      core.autocrlf = false;
    };
  };

  home.packages = with pkgs; [
    minicom
  ];
}
