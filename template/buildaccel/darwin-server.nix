{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.jw.buildAccel.server;
  inventory = import ./inventory.nix { inherit lib; };
  e = inventory.servers.${cfg.name};
  qemu = "${config.nix.linux-builder.package.nixosConfig.virtualisation.qemu.package}/bin/qemu-system-aarch64";
  socketfilterfw = "/usr/libexec/ApplicationFirewall/socketfilterfw";
  status = pkgs.writeShellScriptBin "buildaccel-server-status" ''
    ${pkgs.curl}/bin/curl -s --max-time 3 http://127.0.0.1:3633/ || echo unreachable
  '';
in
{
  options.jw.buildAccel.server = {
    enable = lib.mkEnableOption "buildaccel Linux builder server";
    name = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (builtins.attrNames inventory.servers));
      default = inventory.byHostName config.networking.hostName inventory.servers;
      description = "Server inventory entry for this Mac.";
    };
    bootstrap = lib.mkOption {
      type = lib.types.bool;
      default = builtins.getEnv "BUILDACCEL_BOOTSTRAP" == "1";
      description = "Start the stock builder before building the compile server image.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = cfg.name != null;
            message = "buildaccel: no server inventory entry for hostName '${config.networking.hostName}'; set jw.buildAccel.server.name explicitly.";
          }
        ];
      }
      (lib.mkIf (cfg.name != null) {
        nix.linux-builder = {
          enable = true;
          ephemeral = true;
          config = { lib, ... }: {
            imports = lib.optionals (!cfg.bootstrap) [
              (import ./server-core.nix {
                jobs = e.vm.cores;
                allow = [ "10.0.2.2/32" "192.168.0.0/24" ];
              })
            ];
            virtualisation = {
              cores = e.vm.cores;
              darwin-builder.memorySize = e.vm.memorySize;
              forwardPorts = lib.mkIf (!cfg.bootstrap) (
                lib.mkForce [
                  {
                    from = "host";
                    host.address = "127.0.0.1";
                    host.port = 31022;
                    guest.port = 22;
                  }
                  {
                    from = "host";
                    host.address = "0.0.0.0";
                    host.port = e.port;
                    guest.port = 3632;
                  }
                  {
                    from = "host";
                    host.address = "127.0.0.1";
                    host.port = 3633;
                    guest.port = 3633;
                  }
                ]
              );
            };
          };
        };
        launchd.daemons.linux-builder.serviceConfig.Nice = 5;
        environment.systemPackages = [ status ];
        system.activationScripts.postActivation.text = lib.mkIf (!cfg.bootstrap) (
          lib.mkAfter ''
            if ${socketfilterfw} --getglobalstate | /usr/bin/grep -q enabled; then
              ${socketfilterfw} --add ${qemu}
              ${socketfilterfw} --unblockapp ${qemu}
            fi
          ''
        );
      })
    ]
  );
}
