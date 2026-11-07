# NixOS compile server (x86_64-linux and aarch64-linux). Off by default.
{ config, lib, ... }:
let
  cfg = config.jw.buildAccel.server;
in
{
  # The import list is static; cfg is only forced when server-core's
  # `mkIf enable` is evaluated, after all options are declared.
  imports = [
    (import ./server-core.nix {
      inherit (cfg) enable jobs;
      allow = cfg.allowedClients;
    })
  ];

  options.jw.buildAccel.server = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run the buildaccel distccd compile server.";
    };
    jobs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8;
      description = "Maximum concurrent compile jobs.";
    };
    allowedClients = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "192.168.0.0/24" ];
      description = "Client addresses (IP[/BITS]) passed to distccd --allow.";
    };
  };
}
