{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./common

    ./darwin
  ];

  programs.git = {
    # Sign
    signing = {
      signByDefault = true;
      key = "";
    };
    settings.gpg = {
      format = "ssh";
      ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };

    settings.user = {
      name = "Jerry Wu";
      email = "";
    };
  };
  
  home.packages = with pkgs; [
  ];
}
