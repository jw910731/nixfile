#!@bash@
# shellcheck shell=bash
# buildaccel compiler shim (generated per compiler binary by shim.nix).
# Normalises the argv of compile-only (-c) calls so the result does not
# depend on where the compile runs, then hands the call to the launcher when
# acceleration is enabled on this host. The compiler argv is identical with
# and without acceleration. Prints nothing itself.

real='@real@'
mode='@mode@'

args=("$@")

has_c=0
for arg in "$@"; do
  if [[ $arg == -c ]]; then
    has_c=1
    break
  fi
done

if ((has_c)); then
  if [[ $mode == gcc ]]; then
    # cc-wrapper only puts bintools on PATH; a remote gcc has no such PATH.
    args+=('-B@bintools@/bin/')
  else
    has_dir=0
    for arg in "$@"; do
      if [[ $arg == -fdebug-compilation-dir* || $arg == -ffile-compilation-dir* ]]; then
        has_dir=1
        break
      fi
    done
    if ((!has_dir)); then
      args+=("-fdebug-compilation-dir=$(pwd -P)")
    fi
  fi

  R="${BUILDACCEL_ROOT:-/run/buildaccel/v1}"
  if [[ -f $R/enabled && -r $R/enabled ]]; then
    exec '@launcher@/bin/buildaccel-launcher' "$real" "${args[@]}"
  fi
fi

exec "$real" "${args[@]}"
