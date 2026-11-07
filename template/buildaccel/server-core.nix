# Module builder for the buildaccel distccd compile server; reused by the
# NixOS server module (nixos-server.nix) and the nix-darwin linux-builder VM
# (darwin-server.nix). `enable` lets nixos-server.nix import it
# unconditionally and gate it lazily, since `imports` cannot depend on
# `config`.
{
  jobs,
  allow,
  port ? 3632,
  statsPort ? 3633,
  enable ? true,
}:
{
  config,
  pkgs,
  lib,
  utils,
  ...
}:
let
  server = import ./server-pkgs.nix { inherit pkgs; };
  user = "buildaccel-distcc";
  tmp = "/var/tmp/buildaccel-distccd";
in
{
  config = lib.mkIf enable {
    assertions = [
      {
        assertion = allow != [ ];
        message = "buildaccel: server-core needs at least one `allow` entry";
      }
    ];

    users.users.${user} = {
      isSystemUser = true;
      group = user;
    };
    users.groups.${user} = { };

    # /build: the resolver recreates the client's build directory here so
    # gcc records the client path in debug info.
    systemd.tmpfiles.rules = [
      "d /build 0755 ${user} ${user} 1d"
      "d ${tmp} 0750 ${user} ${user} 1d"
    ];

    systemd.services.buildaccel-distccd = {
      description = "buildaccel distcc compile server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      # nix-store for on-demand compiler substitution, logger for the resolver.
      path = [
        config.nix.package
        pkgs.util-linux
      ];
      serviceConfig = {
        # Each entry is one argv token: allow entries are never shell- or
        # systemd-interpreted.
        ExecStart = utils.escapeSystemdExecArgs (
          [
            "${server.distccPatched}/bin/distccd"
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
            "--allow"
            a
          ]) allow
          ++ [
            "--jobs"
            jobs
            "--nice"
            5
            "--stats"
            "--stats-port"
            statsPort
          ]
        );
        User = user;
        Group = user;
        Environment = [
          "DISTCC_NIX_RESOLVER=${server.resolver}/bin/buildaccel-resolver"
          "TMPDIR=${tmp}"
        ];
        Restart = "always";
      };
    };

    networking.firewall.allowedTCPPorts = [
      port
      statsPort
    ];
  };
}
