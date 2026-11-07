# Client launcher and stdio bridge for build acceleration.
# Generic code only: host data (servers, health, sockets, ccache.conf) is read
# at runtime from ${BUILDACCEL_ROOT:-/run/buildaccel/v1}. See launcher.sh.
{ pkgs }:
pkgs.runCommand "buildaccel-launcher" { } ''
  mkdir -p $out/bin
  substitute ${./bridge.sh} $out/bin/buildaccel-bridge \
    --subst-var-by bash ${pkgs.bash} \
    --subst-var-by socat ${pkgs.socat}
  substitute ${./launcher.sh} $out/bin/buildaccel-launcher \
    --subst-var-by bash ${pkgs.bash} \
    --subst-var-by coreutils ${pkgs.coreutils} \
    --subst-var-by findutils ${pkgs.findutils} \
    --subst-var-by ccache ${pkgs.ccache} \
    --subst-var-by distcc ${pkgs.distcc} \
    --subst-var-by distccversion ${pkgs.lib.escapeShellArg (pkgs.lib.escapeRegex pkgs.distcc.version)} \
    --subst-var-by bridge $out/bin/buildaccel-bridge
  chmod 0555 $out/bin/buildaccel-bridge $out/bin/buildaccel-launcher
  if grep -n '@[a-z][a-z]*@' $out/bin/buildaccel-bridge $out/bin/buildaccel-launcher; then
    echo "buildaccel-launcher: unsubstituted placeholder" >&2
    exit 1
  fi
  ${pkgs.bash}/bin/bash -n $out/bin/buildaccel-bridge
  ${pkgs.bash}/bin/bash -n $out/bin/buildaccel-launcher
''
