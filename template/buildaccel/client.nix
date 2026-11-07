{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.jw.buildAccel.client;
  inventory = import ./inventory.nix { inherit lib; };
  launcher = import ./launcher.nix { inherit pkgs; };
  scripts = import ./client-scripts.nix { inherit pkgs launcher; };
  serversFile = pkgs.writeText "buildaccel-servers" (
    lib.concatStrings (
      lib.mapAttrsToList (
        name: server:
        lib.concatMapStrings (system: "${name} ${toString server.slots} ${system}\n") server.systems
      ) cfg.servers
    )
  );
  cacheConfig = pkgs.writeText "buildaccel-ccache.conf" ''
    cache_dir = /var/cache/buildaccel/ccache
    max_size = ${cfg.cacheSize}
    direct_mode = true
    depend_mode = false
    hash_dir = true
    compression = true
    umask = 007
    hard_link = false
    file_clone = false
    stats = true
  '';
in
{
  options.jw.buildAccel.client = {
    enable = lib.mkEnableOption "build acceleration on this client";
    servers = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }: {
            options = {
              hostName = lib.mkOption { type = lib.types.str; };
              address = lib.mkOption {
                type = lib.types.str;
                default = "${name}.local";
              };
              port = lib.mkOption {
                type = lib.types.port;
                default = 3632;
              };
              systems = lib.mkOption { type = lib.types.listOf lib.types.str; };
              slots = lib.mkOption { type = lib.types.ints.positive; };
              vm = lib.mkOption { type = lib.types.attrsOf lib.types.ints.positive; };
            };
          }
        )
      );
      description = ''
        Inventory entries for the host's system are defined by default.
        Set individual fields per entry to override them, for example address
        or port. Replace the whole set with lib.mkForce { ... }.
      '';
    };
    cacheSize = lib.mkOption {
      type = lib.types.str;
      default = "10G";
      description = "Maximum shared ccache size.";
    };
  };
  config = lib.mkMerge [
    {
      _module.args.buildAccel = (import ./lib.nix { inherit lib; }).forPkgs pkgs;
      jw.buildAccel.client.servers = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault)) (
        inventory.forSystem pkgs.stdenv.hostPlatform.system inventory.servers
      );
    }
    (lib.mkIf cfg.enable {
      assertions =
        lib.mapAttrsToList (name: _: {
          assertion = builtins.match "[a-z][a-z0-9-]{0,31}" name != null;
          message = "buildaccel: invalid server name '${name}' (expected [a-z][a-z0-9-]{0,31})";
        }) cfg.servers
        ++ [
          {
            assertion = config.nix.settings.sandbox != false;
            message = "buildaccel: client requires nix.settings.sandbox not to be false";
          }
        ];
      systemd.tmpfiles.rules = [
        "d /run/buildaccel 0755 root root -"
        "d /run/buildaccel/v1 0755 root root -"
        "f+ /run/buildaccel/v1/enabled 0644 root root - 1"
        "C+ /run/buildaccel/v1/servers - - - - ${serversFile}"
        "C+ /run/buildaccel/v1/ccache.conf - - - - ${cacheConfig}"
        "d /run/buildaccel/v1/sock 0750 root nixbld -"
        "d /run/buildaccel/v1/state 2770 root nixbld -"
        "d /run/buildaccel/v1/state/distcc 2770 root nixbld -"
        "d /var/cache/buildaccel 0755 root root -"
        "d /var/cache/buildaccel/ccache 2770 root nixbld -"
        "d /run/buildaccel/v1/health 0755 root root -"
      ];
      nix.settings.pre-build-hook = scripts.hook;
      systemd.services =
        lib.mapAttrs' (
          name: server:
          lib.nameValuePair "buildaccel-forward-${name}" {
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.socat}/bin/socat UNIX-LISTEN:/run/buildaccel/v1/sock/${name},fork,unlink-early,mode=0660,group=nixbld TCP:${server.address}:${toString server.port},connect-timeout=3";
              Restart = "always";
              ProtectSystem = "strict";
              ReadWritePaths = [ "/run/buildaccel/v1/sock" ];
              NoNewPrivileges = true;
              PrivateTmp = true;
            };
          }
        ) cfg.servers
        // {
          buildaccel-health = {
            after = map (name: "buildaccel-forward-${name}.service") (builtins.attrNames cfg.servers);
            serviceConfig = {
              Type = "oneshot";
              User = "root";
              ExecStart = lib.escapeShellArgs (
                [
                  "${scripts.health}"
                  "${pkgs.stdenv.cc.cc}/bin/gcc"
                  "${pkgs.stdenv.cc.bintools}/bin"
                ]
                ++ builtins.attrNames cfg.servers
              );
            };
          };
        };
      systemd.timers.buildaccel-health = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "10s";
          OnUnitActiveSec = "30s";
        };
      };
      environment.systemPackages = [ scripts.status ];
      # A shell interpreter drops setgid credentials; use the upstream Perl
      # wrapper pattern (programs/ccache.nix), clearing all inherited settings.
      security.wrappers.buildaccel-ccache = {
        owner = "root";
        group = "nixbld";
        setuid = false;
        setgid = true;
        source = pkgs.writeScript "buildaccel-ccache.pl" ''
          #!${pkgs.perl}/bin/perl
          %ENV = ( CCACHE_DIR => '/var/cache/buildaccel/ccache' );
          sub untaint {
            my $v = shift;
            return '-s' if $v eq '-s';
            return '-z' if $v eq '-z';
            return '-C' if $v eq '-C';
            return '-V' if $v eq '-V';
            exit 1;
          }
          exec('${pkgs.ccache}/bin/ccache', map { untaint $_ } @ARGV);
        '';
      };
    })
  ];
}
