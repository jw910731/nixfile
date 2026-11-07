{ pkgs, launcher }:
{
  # The hook's mount root includes v1, while health/status read v1 itself.
  # The daemon hook and systemd health writer run as root: their environment
  # overrides are controlled by the daemon/service, not by build users.
  hook = pkgs.writeShellScript "buildaccel-pre-build-hook" ''
    if [[ -f ''${1:-} ]] && ${pkgs.gnugrep}/bin/grep -Fq buildaccel-optin-v1 "$1"; then
      printf 'extra-sandbox-paths\n'
      root=''${BUILDACCEL_MOUNT_ROOT:-/run/buildaccel}
      cache=''${BUILDACCEL_CACHE_DIR:-/var/cache/buildaccel/ccache}
      if [[ -d $root ]]; then printf '%s\n' "$root"; fi
      if [[ -d $cache ]]; then printf '%s\n' "$cache"; fi
      printf '\n'
    fi
    exit 0
  '';
  health = pkgs.writeShellScript "buildaccel-health" ''
    set -euo pipefail
    root=''${BUILDACCEL_ROOT:-/run/buildaccel/v1}
    probe=''${BUILDACCEL_LAUNCHER:-${launcher}/bin/buildaccel-launcher}
    gcc=$1
    bin=$2
    shift 2
    tmp=""
    trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT
    for name in "$@"; do
      tmp=$(${pkgs.coreutils}/bin/mktemp "$root/health/.$name.XXXXXX")
      # A failed remote compile is a valid "down" record, not a service failure.
      "$probe" --health-check "$name" "$gcc" "$bin" >"$tmp" || true
      ${pkgs.coreutils}/bin/chmod 0644 "$tmp"
      ${pkgs.coreutils}/bin/mv -f "$tmp" "$root/health/$name"
      tmp=""
    done
  '';
  status = pkgs.writeShellScriptBin "buildaccel-status" ''
    set -euo pipefail
    root=''${BUILDACCEL_ROOT:-/run/buildaccel/v1}
    wrapper=''${BUILDACCEL_CCACHE_WRAPPER:-/run/wrappers/bin/buildaccel-ccache}
    now=''${BUILDACCEL_NOW:-$(${pkgs.coreutils}/bin/date +%s)}
    declare -A seen=()
    while read -r name _; do
      [[ -z ''${seen[$name]:-} ]] || continue
      seen[$name]=1
      state=down epoch="" reason=missing age=0
      if [[ -r $root/health/$name ]]; then
        read -r state epoch reason <"$root/health/$name" || true
        if [[ $epoch =~ ^[0-9]{1,12}$ ]]; then
          age=$((now - 10#$epoch))
          if [[ $state == ok && $age -ge 0 && $age -le 120 ]]; then
            state=healthy
            reason=""
          elif [[ $state == ok ]]; then
            state=down
            reason=stale
          fi
        else
          state=down age=0 reason=invalid
        fi
      fi
      printf '%s %s %ss%s\n' "$name" "$state" "$age" "''${reason:+ $reason}"
    done <"$root/servers"
    exec "$wrapper" -s
  '';
}
