{ pkgs, config, ... }:
{
  programs.git = {
    # Sign
    signing = {
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIlmEeuqIj2EQuHMhiua+C34/mibY9KeMwAyQNj299nl";
    };
    extraConfig.gpg = {
      format = "ssh";
    };
  };

  programs.zsh.sessionVariables =
    { }
    // (pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      "SSH_AUTH_SOCK" =
        "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    });
}
