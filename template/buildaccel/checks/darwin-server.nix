{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  plain = builtins.unsafeDiscardStringContext;
  mkConfig =
    hostName: server:
    (inputs.darwin.lib.darwinSystem {
      modules = [
        ../darwin-server.nix
        {
          nixpkgs.hostPlatform = "aarch64-darwin";
          system.stateVersion = 6;
          networking.hostName = hostName;
          jw.buildAccel.server = {
            enable = true;
            bootstrap = false;
          }
          // server;
        }
      ];
    }).config;
  studio = mkConfig "jw910731-Mac-Studio" { };
  mini = mkConfig "MacMini" { };
  bootstrap = mkConfig "jw910731-Mac-Studio" { bootstrap = true; };
  disabled = mkConfig "unknown-mac" { enable = false; };
  vm = studio.nix.linux-builder.package.nixosConfig;
  miniVm = mini.nix.linux-builder.package.nixosConfig;
  bootstrapVm = bootstrap.nix.linux-builder.package.nixosConfig;
  service = studio.launchd.daemons.linux-builder.serviceConfig;
  forward = address: hostPort: guestPort: {
    from = "host";
    proto = "tcp";
    host = {
      inherit address;
      port = hostPort;
    };
    guest = {
      address = "";
      port = guestPort;
    };
  };
  qemu = "${vm.virtualisation.qemu.package}/bin/qemu-system-aarch64";
  activation = plain studio.system.activationScripts.postActivation.text;
  command = plain vm.systemd.services.buildaccel-distccd.serviceConfig.ExecStart;
  hasStatus =
    c: builtins.any (p: lib.getName p == "buildaccel-server-status") c.environment.systemPackages;
  hasFirewall =
    c: lib.hasInfix "socketfilterfw" (plain c.system.activationScripts.postActivation.text);
in
assert studio.jw.buildAccel.server.name == "macstudio";
assert studio.nix.linux-builder.enable;
assert
  vm.virtualisation.forwardPorts == [
    (forward "127.0.0.1" 31022 22)
    (forward "0.0.0.0" 3632 3632)
    (forward "127.0.0.1" 3633 3633)
  ];
assert vm.virtualisation.cores == 8;
assert vm.virtualisation.darwin-builder.memorySize == 12288;
assert vm.virtualisation.memorySize == 12288;
assert service.Nice == 5 && service.RunAtLoad && service.KeepAlive;
assert lib.hasInfix ''"--allow" "10.0.2.2/32"'' command;
assert lib.hasInfix ''"--jobs" "8"'' command;
assert lib.hasInfix "socketfilterfw --getglobalstate | /usr/bin/grep -q enabled" activation;
assert lib.hasInfix "socketfilterfw --add ${plain qemu}" activation;
assert lib.hasInfix "socketfilterfw --unblockapp ${plain qemu}" activation;
assert hasStatus studio;
assert mini.jw.buildAccel.server.name == "macmini";
assert miniVm.virtualisation.cores == 8;
assert miniVm.virtualisation.darwin-builder.memorySize == 8192;
assert miniVm.virtualisation.memorySize == 8192;
assert bootstrap.nix.linux-builder.enable;
assert bootstrapVm.virtualisation.cores == 8;
assert bootstrapVm.virtualisation.darwin-builder.memorySize == 12288;
assert bootstrapVm.virtualisation.memorySize == 12288;
assert !(bootstrapVm.systemd.services ? buildaccel-distccd);
assert bootstrapVm.virtualisation.forwardPorts == [ (forward "" 31022 22) ];
assert !(hasFirewall bootstrap);
assert hasStatus bootstrap;
assert studio.nix.distributedBuilds && studio.nix.settings.builders-use-substitutes;
assert bootstrap.nix.distributedBuilds && bootstrap.nix.settings.builders-use-substitutes;
assert builtins.length studio.nix.buildMachines == 1;
assert (builtins.head studio.nix.buildMachines).hostName == "linux-builder";
assert lib.hasInfix "Host linux-builder"
  studio.environment.etc."ssh/ssh_config.d/100-linux-builder.conf".text;
assert !disabled.nix.linux-builder.enable;
assert !(disabled.launchd.daemons ? linux-builder);
assert !(hasStatus disabled);
assert !(hasFirewall disabled);
assert !disabled.nix.distributedBuilds;
assert !(disabled.nix.settings.builders-use-substitutes or false);
assert disabled.nix.buildMachines == [ ];
pkgs.runCommand "buildaccel-darwin-server-check" { } ''
  touch "$out"
''
