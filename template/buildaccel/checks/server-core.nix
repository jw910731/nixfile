# Evaluation-level check of server-core.nix and nixos-server.nix.
{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  str = builtins.unsafeDiscardStringContext;
  mkSys =
    system: modules:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        {
          fileSystems."/" = {
            device = "/dev/vda";
            fsType = "ext4";
          };
          boot.loader.grub.enable = false;
          system.stateVersion = "25.11";
        }
      ]
      ++ modules;
    };
  server =
    mod:
    mkSys "x86_64-linux" [
      ../nixos-server.nix
      mod
    ];
  core = args: mkSys "x86_64-linux" [ (import ../server-core.nix args) ];

  on = server { jw.buildAccel.server.enable = true; };
  off = server { jw.buildAccel.server.enable = false; };
  unset = server { };
  vm = core {
    jobs = 3;
    allow = [ "10.0.2.2/32" ];
    port = 13632;
  };
  hostile = server {
    jw.buildAccel.server = {
      enable = true;
      allowedClients = [
        "10.0.0.0/8"
        "a b;$(id)%n"
      ];
    };
  };
  empty = core {
    jobs = 1;
    allow = [ ];
  };

  sp = import ../server-pkgs.nix { pkgs = on.pkgs; };
  distccd = str "${sp.distccPatched}/bin/distccd";
  resolver = str "${sp.resolver}/bin/buildaccel-resolver";

  # Hand-written systemd quoting (one JSON string per argv token), independent
  # of the module's escaping helper.
  q = t: "\"${t}\"";
  expectedExec =
    {
      port ? "3632",
      allow ? [ (q "192.168.0.0/24") ],
      jobs ? "8",
      statsPort ? "3633",
    }:
    lib.concatStringsSep " " (
      map q [
        distccd
        "--daemon"
        "--no-detach"
        "--log-stderr"
        "--log-level"
        "info"
        "--listen"
        "0.0.0.0"
        "--port"
        port
      ]
      ++ lib.concatMap (a: [
        (q "--allow")
        a
      ]) allow
      ++ map q [
        "--jobs"
        jobs
        "--nice"
        "5"
        "--stats"
        "--stats-port"
        statsPort
      ]
    );

  unit = sys: sys.config.systemd.services.buildaccel-distccd;
  exec = sys: str (unit sys).serviceConfig.ExecStart;
  rules = sys: sys.config.systemd.tmpfiles.rules;
  ports = sys: sys.config.networking.firewall.allowedTCPPorts;
  ruleBuild = "d /build 0755 buildaccel-distcc buildaccel-distcc 1d";
  ruleTmp = "d /var/tmp/buildaccel-distccd 0750 buildaccel-distcc buildaccel-distcc 1d";
  absent =
    sys:
    !(sys.config.systemd.services ? buildaccel-distccd)
    && !(sys.config.users.users ? buildaccel-distcc)
    && !(sys.config.users.groups ? buildaccel-distcc)
    && !(lib.elem ruleBuild (rules sys))
    && !(lib.elem ruleTmp (rules sys))
    && !(lib.elem 3632 (ports sys))
    && !(lib.elem 3633 (ports sys));
  failedMsgs = sys: map (a: a.message) (lib.filter (a: !a.assertion) sys.config.assertions);

  cases = [
    {
      name = "enabled: ExecStart exact argv";
      ok = exec on == expectedExec { };
      got = exec on;
    }
    {
      name = "enabled: runs as buildaccel-distcc, not root";
      ok =
        (unit on).serviceConfig.User == "buildaccel-distcc"
        && (unit on).serviceConfig.Group == "buildaccel-distcc"
        && !((unit on).serviceConfig.DynamicUser or false);
    }
    {
      name = "enabled: Environment";
      ok =
        map str (unit on).serviceConfig.Environment == [
          "DISTCC_NIX_RESOLVER=${resolver}"
          "TMPDIR=/var/tmp/buildaccel-distccd"
        ];
      got = toString (map str (unit on).serviceConfig.Environment);
    }
    {
      name = "enabled: restart, wantedBy, path";
      ok =
        (unit on).serviceConfig.Restart == "always"
        && lib.elem "multi-user.target" (unit on).wantedBy
        && lib.elem (str "${on.config.nix.package}") (map str (unit on).path)
        && lib.elem (str "${on.pkgs.util-linux}") (map str (unit on).path);
    }
    {
      name = "enabled: firewall 3632 and 3633";
      ok = lib.elem 3632 (ports on) && lib.elem 3633 (ports on);
      got = toString (ports on);
    }
    {
      name = "enabled: user, group, tmpfiles";
      ok =
        on.config.users.users.buildaccel-distcc.isSystemUser
        && on.config.users.users.buildaccel-distcc.group == "buildaccel-distcc"
        && on.config.users.groups ? buildaccel-distcc
        && lib.elem ruleBuild (rules on)
        && lib.elem ruleTmp (rules on);
    }
    {
      name = "enabled: no failed assertions";
      ok = failedMsgs on == [ ];
    }
    {
      name = "disabled (explicit): nothing exists";
      ok = absent off;
    }
    {
      name = "disabled (default): nothing exists";
      ok = absent unset;
    }
    {
      name = "vm args: ExecStart exact argv";
      ok =
        exec vm == expectedExec {
          port = "13632";
          allow = [ (q "10.0.2.2/32") ];
          jobs = "3";
        };
      got = exec vm;
    }
    {
      name = "vm args: firewall 13632 and 3633";
      ok =
        lib.sort lib.lessThan (ports vm) == [
          3633
          13632
        ];
      got = toString (ports vm);
    }
    {
      name = "hostile allow entry stays one escaped token";
      ok =
        exec hostile == expectedExec {
          allow = [
            (q "10.0.0.0/8")
            (q "a b;$$(id)%%n")
          ];
        };
      got = exec hostile;
    }
    {
      name = "empty allow: assertion message";
      ok = failedMsgs empty == [ "buildaccel: server-core needs at least one `allow` entry" ];
      got = toString (failedMsgs empty);
    }
    {
      name = "empty allow: toplevel fails to evaluate";
      ok = !(builtins.tryEval empty.config.system.build.toplevel.drvPath).success;
    }
    {
      name = "enabled: toplevel evaluates (control for the case above)";
      ok = (builtins.tryEval on.config.system.build.toplevel.drvPath).success;
    }
  ];
  failed = lib.filter (c: !c.ok) cases;
in
if failed != [ ] then
  throw (
    "buildaccel server-core check failed:\n"
    + lib.concatMapStringsSep "\n" (
      c: "  ${c.name}${lib.optionalString (c ? got) ": got ${c.got}"}"
    ) failed
  )
else
  pkgs.runCommand "buildaccel-server-core-check" { } ''
    printf 'PASS %s\n' ${lib.escapeShellArgs (map (c: c.name) cases)}
    touch "$out"
  ''
