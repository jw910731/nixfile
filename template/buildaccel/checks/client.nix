{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  clean = x: builtins.unsafeDiscardStringContext (toString x);
  mkSys =
    enable: extra:
    inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ../client.nix
        {
          fileSystems."/" = {
            device = "/dev/vda";
            fsType = "ext4";
          };
          boot.loader.grub.enable = false;
          system.stateVersion = "26.05";
          jw.buildAccel.client.enable = enable;
        }
        ({ buildAccel, pkgs, ... }: {
          boot.kernelPackages = pkgs.linuxPackagesFor (buildAccel.accelerate pkgs.linux_6_18);
          environment.systemPackages = [
            (buildAccel.accelerate pkgs.pigz)
            pkgs.lz4
          ];
        })
        extra
      ];
    };
  on = mkSys true { };
  off = mkSys false { };
  addressOnly = mkSys true {
    jw.buildAccel.client.servers.macstudio.address = "10.0.2.2";
  };
  replaced = mkSys true {
    jw.buildAccel.client.servers = lib.mkForce {
      qa-a = {
        hostName = "qa-a";
        address = "10.0.2.2";
        port = 13632;
        systems = [ "aarch64-linux" ];
        slots = 3;
        vm = {
          cores = 1;
          memorySize = 1;
        };
      };
    };
  };
  overridden = mkSys true {
    jw.buildAccel.client.servers.macstudio = {
      address = "10.0.2.2";
      port = 13632;
      hostName = "qa";
      systems = [ "aarch64-linux" ];
      slots = 3;
      vm = {
        cores = 1;
        memorySize = 1;
      };
    };
  };
  services = sys: sys.config.systemd.services;
  units = sys: lib.filter (lib.hasPrefix "buildaccel-") (builtins.attrNames (services sys));
  rules = sys: map clean (lib.filter (lib.hasInfix "/buildaccel") sys.config.systemd.tmpfiles.rules);
  package =
    sys: name:
    lib.findFirst (
      p: p.pname or "" == name
    ) (throw "missing ${name}") sys.config.environment.systemPackages;
  forward = sys: clean (services sys).buildaccel-forward-macstudio.serviceConfig.ExecStart;
  expectedForward =
    address: port:
    "${clean on.pkgs.socat}/bin/socat UNIX-LISTEN:/run/buildaccel/v1/sock/macstudio,fork,unlink-early,mode=0660,group=nixbld TCP:${address}:${port},connect-timeout=3";
  inventoryServers = import ../servers.nix;
  serverFile = on.pkgs.writeText "buildaccel-servers" (
    lib.concatMapStrings (
      name:
      let
        server = inventoryServers.${name};
      in
      lib.concatMapStrings (system: "${name} ${toString server.slots} ${system}\n") server.systems
    ) (builtins.sort builtins.lessThan (builtins.attrNames inventoryServers))
  );
  cacheFile = on.pkgs.writeText "buildaccel-ccache.conf" ''
    cache_dir = /var/cache/buildaccel/ccache
    max_size = 10G
    direct_mode = true
    depend_mode = false
    hash_dir = true
    compression = true
    umask = 007
    hard_link = false
    file_clone = false
    stats = true
  '';
  expectedRules = [
    "d /run/buildaccel 0755 root root -"
    "d /run/buildaccel/v1 0755 root root -"
    "f+ /run/buildaccel/v1/enabled 0644 root root - 1"
    "C+ /run/buildaccel/v1/servers - - - - ${clean serverFile}"
    "C+ /run/buildaccel/v1/ccache.conf - - - - ${clean cacheFile}"
    "d /run/buildaccel/v1/sock 0750 root nixbld -"
    "d /run/buildaccel/v1/state 2770 root nixbld -"
    "d /run/buildaccel/v1/state/distcc 2770 root nixbld -"
    "d /var/cache/buildaccel 0755 root root -"
    "d /var/cache/buildaccel/ccache 2770 root nixbld -"
    "d /run/buildaccel/v1/health 0755 root root -"
  ];
  eq = name: actual: expected: ''
    eq ${lib.escapeShellArg (clean actual)} ${lib.escapeShellArg (clean expected)} ${lib.escapeShellArg name}
  '';
  fakeLauncher = pkgs.writeShellScriptBin "buildaccel-launcher" ''
    [[ $1 == --health-check && $3 == gcc && $4 == bin ]] || exit 2
    # The previous complete record must still be visible during the next probe.
    if [[ -n ''${EXPECT_OLD:-} ]]; then
      [[ $(<"$BUILDACCEL_ROOT/health/$2") == "$EXPECT_OLD" ]] || exit 2
    fi
    printf '%s\n' "$PROBE_RESULT"
    exit "''${PROBE_EXIT:-0}"
  '';
  scripts = import ../client-scripts.nix {
    inherit pkgs;
    launcher = fakeLauncher;
  };
  fakeWrapper = pkgs.writeShellScript "fake-buildaccel-ccache" ''
    [[ $# == 1 && $1 == -s ]] || exit 2
    printf 'ccache statistics\n'
  '';
in
pkgs.runCommand "buildaccel-check-client"
  {
    passthru = { inherit scripts on off; };
  }
  ''
    set -euo pipefail
    fail() { echo "FAIL: $*" >&2; exit 1; }
    eq() { [[ $1 == "$2" ]] || fail "$3: got [$1] want [$2]"; echo "ok: $3"; }
    bytes() { cmp "$1" "$2" || fail "$3"; echo "ok: $3"; }
    ${eq "disabled hook" (off.config.nix.settings ? pre-build-hook) false}
    ${eq "disabled units" (builtins.toJSON (units off)) "[]"}
    ${eq "disabled timer" (off.config.systemd.timers ? buildaccel-health) false}
    ${eq "disabled tmpfiles" (builtins.toJSON (rules off)) "[]"}
    ${eq "disabled wrapper" (off.config.security.wrappers ? buildaccel-ccache) false}
    ${eq "disabled status" (lib.any (
      p: p.name or "" == "buildaccel-status"
    ) off.config.environment.systemPackages) false}
    ${eq "enabled units" (builtins.toJSON (
      units on
    )) ''["buildaccel-forward-macmini","buildaccel-forward-macstudio","buildaccel-health"]''}
    ${eq "enabled tmpfiles exact" (builtins.toJSON (rules on)) (builtins.toJSON expectedRules)}
    ${eq "enabled forward exact" (forward on) (expectedForward "jw910731-Mac-Studio.local" "3632")}
    ${eq "address-only forward exact" (forward addressOnly) (expectedForward "10.0.2.2" "3632")}
    ${eq "address-only units" (builtins.toJSON (
      units addressOnly
    )) ''["buildaccel-forward-macmini","buildaccel-forward-macstudio","buildaccel-health"]''}
    ${eq "address-only servers file exact" (builtins.toJSON (
      lib.filter (lib.hasPrefix "C+ /run/buildaccel/v1/servers ") (rules addressOnly)
    )) (builtins.toJSON [ "C+ /run/buildaccel/v1/servers - - - - ${clean serverFile}" ])}
    ${eq "forced replacement units" (builtins.toJSON (
      units replaced
    )) ''["buildaccel-forward-qa-a","buildaccel-health"]''}
    ${eq "override forward exact" (forward overridden) (expectedForward "10.0.2.2" "13632")}
    ${eq "timer boot" on.config.systemd.timers.buildaccel-health.timerConfig.OnBootSec "10s"}
    ${eq "timer interval" on.config.systemd.timers.buildaccel-health.timerConfig.OnUnitActiveSec "30s"}
    ${eq "enabled hook" (on.config.nix.settings ? pre-build-hook) true}
    ${eq "enabled status" (lib.any (
      p: p.name or "" == "buildaccel-status"
    ) on.config.environment.systemPackages) true}
    ${eq "wrapper setgid" on.config.security.wrappers.buildaccel-ccache.setgid true}
    ${eq "wrapper group" on.config.security.wrappers.buildaccel-ccache.group "nixbld"}
    ${eq "kernel hash invariant" on.config.boot.kernelPackages.kernel.drvPath
      off.config.boot.kernelPackages.kernel.drvPath
    }
    ${eq "pigz hash invariant" (package on "pigz").drvPath (package off "pigz").drvPath}
    ${eq "lz4 hash invariant" (package on "lz4").drvPath (package off "lz4").drvPath}
    export BUILDACCEL_ROOT=$TMPDIR/root BUILDACCEL_MOUNT_ROOT=$TMPDIR/root BUILDACCEL_CACHE_DIR=$TMPDIR/cache
    export BUILDACCEL_CCACHE_WRAPPER=${fakeWrapper} BUILDACCEL_NOW=1000
    mkdir -p "$BUILDACCEL_ROOT/health" "$BUILDACCEL_CACHE_DIR"
    printf '{"__json":"{\\"env\\":{\\"BUILDACCEL_OPTIN\\":\\"buildaccel-optin-v1\\"}}"}' > marker
    printf plain > plain
    ${scripts.hook} marker > got
    printf 'extra-sandbox-paths\n%s\n%s\n\n' "$BUILDACCEL_ROOT" "$BUILDACCEL_CACHE_DIR" > expected
    bytes expected got 'hook both directories'
    rmdir "$BUILDACCEL_CACHE_DIR"
    ${scripts.hook} marker > got
    printf 'extra-sandbox-paths\n%s\n\n' "$BUILDACCEL_ROOT" > expected
    bytes expected got 'hook root only'
    mv "$BUILDACCEL_ROOT" "$TMPDIR/saved"
    mkdir "$BUILDACCEL_CACHE_DIR"
    ${scripts.hook} marker > got
    printf 'extra-sandbox-paths\n%s\n\n' "$BUILDACCEL_CACHE_DIR" > expected
    bytes expected got 'hook cache only'
    rmdir "$BUILDACCEL_CACHE_DIR"
    ${scripts.hook} marker > got
    printf 'extra-sandbox-paths\n\n' > expected
    bytes expected got 'hook no directories'
    mv "$TMPDIR/saved" "$BUILDACCEL_ROOT"
    for arg in plain missing; do
      ${scripts.hook} "$arg" > got
      [[ ! -s got ]] || fail "hook $arg"
    done
    ${scripts.hook} > got
    [[ ! -s got ]] || fail 'hook no arguments'
    export PROBE_RESULT='ok 995'
    ${scripts.health} gcc bin qa-a qa-b
    printf 'ok 995\n' > expected
    bytes expected "$BUILDACCEL_ROOT/health/qa-a" 'health a'
    bytes expected "$BUILDACCEL_ROOT/health/qa-b" 'health b'
    export EXPECT_OLD='ok 995' PROBE_RESULT='down 998 connection refused' PROBE_EXIT=1
    ${scripts.health} gcc bin qa-a qa-b
    printf 'down 998 connection refused\n' > expected
    bytes expected "$BUILDACCEL_ROOT/health/qa-a" 'health down a atomically'
    bytes expected "$BUILDACCEL_ROOT/health/qa-b" 'health down b atomically'
    eq "$(find "$BUILDACCEL_ROOT/health" -type f | wc -l | tr -d ' ')" 2 'health no temporary files'
    printf 'qa-a 3 aarch64-linux\nqa-a 3 x86_64-linux\nqa-b 3 aarch64-linux\n' > "$BUILDACCEL_ROOT/servers"
    printf 'ok 995\n' > "$BUILDACCEL_ROOT/health/qa-a"
    ${scripts.status}/bin/buildaccel-status > got
    printf 'qa-a healthy 5s\nqa-b down 2s connection refused\nccache statistics\n' > expected
    bytes expected got 'status healthy down and ccache'
    printf 'ok 879\n' > "$BUILDACCEL_ROOT/health/qa-a"
    rm "$BUILDACCEL_ROOT/health/qa-b"
    ${scripts.status}/bin/buildaccel-status > got
    printf 'qa-a down 121s stale\nqa-b down 0s missing\nccache statistics\n' > expected
    bytes expected got 'status stale and missing'
    touch "$out"
  ''
