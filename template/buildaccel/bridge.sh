#!@bash@/bin/bash
# shellcheck shell=bash
#
# buildaccel-bridge - stdio bridge used as DISTCC_SSH (template/buildaccel).
#
# distcc 3.4 ssh mode runs "<DISTCC_SSH> <host> distccd --inetd --enable-tcp-insecure"
# (src/ssh.c 227-240). This bridge never runs the trailing arguments: it
# validates <host>, requires the local forwarder socket $R/sock/<host> and
# connects stdio to it. stdout carries the distcc protocol; diagnostics go to
# $TMPDIR/.buildaccel/bridge.log (or nowhere), never to the compile's stderr.
set -u

R="${BUILDACCEL_ROOT:-/run/buildaccel/v1}"
log="${TMPDIR:-/tmp}/.buildaccel/bridge.log"
if [[ -d ${log%/*} && -w ${log%/*} ]]; then
  exec 2>>"$log"
else
  exec 2>/dev/null
fi

host="${1:-}"
if [[ ! $host =~ ^[a-z][a-z0-9-]{0,31}$ ]]; then
  printf 'buildaccel-bridge: refused invalid host name\n' >&2
  exit 2
fi
sock="$R/sock/$host"
if [[ ! -S $sock ]]; then
  printf 'buildaccel-bridge: no socket %s\n' "$sock" >&2
  exit 3
fi
exec @socat@/bin/socat - "UNIX-CONNECT:$sock"
