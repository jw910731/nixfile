{ pkgs, lib, ... }:
{
  home.file.".ssh/common.config_link" = {
      text = ''
      Host *
          ${lib.optionalString pkgs.stdenv.isDarwin ''IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''}
          ForwardAgent yes
          ControlMaster auto
          ControlPath ~/.ssh/ssh_mux_%h_%p_%r
          Compression yes
    '';
    onChange = ''
      cat ~/.ssh/common.config_link > ~/.ssh/common.config
      rm ~/.ssh/.ssh/common.config_link
      chmod 600 ~/.ssh/common.config
    '';
    force = true;
  };
}
