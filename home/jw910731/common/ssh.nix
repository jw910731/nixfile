{ pkgs, lib, ... }:
{
  home.file.".ssh/common.config".text = ''
  Host *
      ${lib.optionalString pkgs.stdenv.isDarwin ''IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''}
      ForwardAgent yes
      ControlMaster auto
      ControlPath ~/.ssh/ssh_mux_%h_%p_%r
  '';
}