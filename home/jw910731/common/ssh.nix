{ pkgs, lib, ... }:
{
  # ControlMaster auto + ControlPersist: the first ssh creates the master, which
  # detaches into the background, so closing that ssh never kills or blocks
  # other sessions sharing it. Released 10 minutes after the last session.
  home.file.".ssh/common.config_link" = {
    text = ''
      Host *
          ${lib.optionalString pkgs.stdenv.isDarwin ''IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''}
          ForwardAgent yes
          ControlMaster auto
          ControlPersist 10m
          ControlPath ~/.ssh/ssh_mux_%h_%p_%r
          Compression yes
    '';
    onChange = ''
      cat ~/.ssh/common.config_link > ~/.ssh/common.config
      rm ~/.ssh/common.config_link
      chmod 600 ~/.ssh/common.config
    '';
    force = true;
  };
}
