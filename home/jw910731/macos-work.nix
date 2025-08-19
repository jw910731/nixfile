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
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";

  programs.git = {
    # Sign
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWoAtGxpKw/xK4SPDUNqeJQCR/foAP1oIAMI+ZFgCa/";
    };
    extraConfig.gpg = {
      format = "ssh";
      ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
    };
    userName = "Jerry Wu";
    userEmail = "jerry.wu@graidtech.com";
  };

  programs.zsh.sessionVariables =
    { }
    // (pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      "SSH_AUTH_SOCK" =
        "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    });

  home.packages = with pkgs; [
  ];
}
