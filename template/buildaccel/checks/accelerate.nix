{ pkgs, inputs }:
let
  inherit (pkgs) lib;
  linux = inputs.nixpkgs.legacyPackages.aarch64-linux;
  x86 = inputs.nixpkgs.legacyPackages.x86_64-linux;
  forPkgs = (import ../lib.nix { inherit lib; }).forPkgs;
  inherit (forPkgs linux) accelerate;
  pigz = accelerate linux.pigz;
  kernel = accelerate linux.linux_6_18;
  clangKernel = accelerate (
    linux.linuxManualConfig {
      inherit (linux.linux_6_18) src version modDirVersion;
      configfile = linux.writeText "c" "";
      allowImportFromDerivation = false;
      stdenv = linux.llvmPackages_21.stdenv;
    }
  );
  crossPigz = (forPkgs x86).accelerate x86.pkgsCross.aarch64-multiplatform.pigz;
  pigzPatched = accelerate (
    linux.pigz.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        printf '\n/* buildaccel patch fixture */\n' >> pigz.c
      '';
    })
  );
  # Linux paths are evaluation data, never dependencies of this Darwin check.
  clean = value: builtins.unsafeDiscardStringContext (toString value);
  environment = drv: drv.env or drv;
  eq = name: actual: expected: ''
    eq ${lib.escapeShellArg (clean actual)} ${lib.escapeShellArg (clean expected)} ${lib.escapeShellArg name}
  '';
  fakeLauncher = pkgs.writeShellScriptBin "buildaccel-launcher" ''
    case $1 in
      --probe)
        printf 'probe\n' >> "$PROBE_LOG"
        printf '%s' "$PROBE_OUTPUT"
        exit "$PROBE_STATUS"
        ;;
      --summary) printf '%s\n' "$FIXED_SUMMARY" ;;
      *) exit 1 ;;
    esac
  '';
  hook = pkgs.replaceVars ../boost-hook.sh {
    launcher = fakeLauncher;
  };
in
pkgs.runCommand "buildaccel-check-accelerate" { } ''
  set -euo pipefail
  fail() { echo "FAIL: $*" >&2; exit 1; }
  eq() { [ "$1" = "$2" ] || fail "$3: got [$1] want [$2]"; echo "ok: $3"; }

  ${eq "a marker" (environment pigz).BUILDACCEL_OPTIN "buildaccel-optin-v1"}
  ${eq "a compiler shim" pigz.stdenv.cc.cc.isBuildAccelShim true}
  ${eq "b gcc kernel CC" (builtins.elem "CC=${kernel.stdenv.cc.cc}/bin/gcc" kernel.makeFlags) true}
  ${eq "c clang kernel CC"
    (builtins.elem "CC=${clangKernel.stdenv.cc.cc}/bin/clang" clangKernel.makeFlags)
    true
  }
  ${eq "c clang raw headers"
    (builtins.elem "CFLAGS_KERNEL=-I${lib.getLib linux.llvmPackages_21.stdenv.cc.cc}/lib/clang/21/include" clangKernel.makeFlags)
    true
  }
  ${eq "d cross compiler shim" crossPigz.stdenv.cc.cc.isBuildAccelShim true}
  ${eq "d cross compiler executable system" crossPigz.stdenv.cc.cc.system "x86_64-linux"}
  ${eq "d cross compiler identity" crossPigz.stdenv.cc.cc.name
    "buildaccel-shim-${x86.pkgsCross.aarch64-multiplatform.stdenv.cc.cc.name}"
  }
  ${eq "d cross compiler store host" (lib.hasInfix "aarch64-linux" (
    builtins.baseNameOf (toString crossPigz.stdenv.cc.cc)
  )) false}
  ${eq "e idempotence" (accelerate pigz).drvPath pigz.drvPath}
  ${eq "f independent evaluation" ((forPkgs linux).accelerate linux.pigz).drvPath pigz.drvPath}
  ${eq "g rejects non-callPackage value" (builtins.tryEval (accelerate { })).success false}
  ${eq "h seed" (environment pigz).NIX_OUTPATH_USED_AS_RANDOM_SEED "buildaccel"}
  ${eq "h patched seed" (environment pigzPatched).NIX_OUTPATH_USED_AS_RANDOM_SEED "buildaccel"}
  ${eq "h distinct derivations" (pigz.drvPath != pigzPatched.drvPath) true}
  ${eq "preserve top-level seed"
    (accelerate (linux.pigz.overrideAttrs { NIX_OUTPATH_USED_AS_RANDOM_SEED = "explicit"; }))
    .NIX_OUTPATH_USED_AS_RANDOM_SEED
    "explicit"
  }
  ${eq "preserve environment seed"
    (accelerate (linux.pigz.overrideAttrs { env.NIX_OUTPATH_USED_AS_RANDOM_SEED = "explicit-env"; }))
    .NIX_OUTPATH_USED_AS_RANDOM_SEED
    "explicit-env"
  }

  export FIXED_SUMMARY='invocations=0 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped='
  # Each subshell has structured-attrs-like shell variables and stdenv arrays.
  # Byte comparisons include the final newline and prohibit extra stdout.
  run_case() {
    local name=$1 enabled=$2 output=$3 status=$4 jobs=$5 mode=$6 probes=$7 parallel=''${8:-yes}
    local dir=$TMPDIR/$name
    mkdir -p "$dir/root"
    if [[ $enabled == yes ]]; then touch "$dir/root/enabled"; fi
    (
      export TMPDIR=$dir BUILDACCEL_ROOT=$dir/root
      export PROBE_LOG=$dir/probe PROBE_OUTPUT="$output" PROBE_STATUS=$status
      system=aarch64-linux
      export -n system
      NIX_BUILD_CORES=4
      if [[ $parallel == yes ]]; then enableParallelBuilding=1; else unset enableParallelBuilding; fi
      preBuildHooks=() postBuildHooks=() exitHooks=()
      source ${hook}
      for h in "''${preBuildHooks[@]}"; do "$h"; done
      if [[ $mode == remote ]]; then
        [[ $NIX_BUILD_CORES == $((4 + output)) ]] || fail "$name build cores"
      else
        [[ $NIX_BUILD_CORES == 4 ]] || fail "$name build cores"
      fi
      [[ $BUILDACCEL_SYSTEM == aarch64-linux && $BUILDACCEL_LOCAL_CORES == 4 ]] || fail "$name exports"
      [[ -d $TMPDIR/.buildaccel ]] || fail "$name record directory"
      ${pkgs.bash}/bin/bash -eu -c '
        [[ $BUILDACCEL_SYSTEM == aarch64-linux && $BUILDACCEL_LOCAL_CORES == 4 ]]
      '
      for h in "''${postBuildHooks[@]}"; do "$h"; done
      [[ $NIX_BUILD_CORES == 4 ]] || fail "$name restored cores"
      for h in "''${exitHooks[@]}"; do "$h"; done
    ) >"$dir/stdout" 2>"$dir/stderr"
    printf 'buildaccel: mode=%s jobs=%s %s\n' "$mode" "$jobs" "$FIXED_SUMMARY" >"$dir/expected"
    cmp "$dir/expected" "$dir/stdout" || fail "$name stdout"
    [[ ! -s $dir/stderr ]] || fail "$name stderr: $(<"$dir/stderr")"
    if [[ $probes == 1 ]]; then
      printf 'probe\n' >"$dir/probe-expected"
      cmp "$dir/probe-expected" "$dir/probe" || fail "$name probe calls"
    else
      [[ ! -e $dir/probe ]] || fail "$name unexpectedly called probe"
    fi
    echo "ok: $name"
  }
  run_case enabled yes 3 0 7 remote 1
  run_case disabled no 3 0 4 local 0
  run_case zero yes 0 0 4 local 1
  run_case above-limit yes 1025 0 4 local 1
  run_case noninteger yes abc 0 4 local 1
  run_case empty yes "" 0 4 local 1
  run_case failing yes 3 1 4 local 1
  run_case nonparallel yes 3 0 1 remote 1 no
  run_case upper-bound yes 1024 0 1028 remote 1
  run_case huge yes 999999999999999999999999 0 4 local 1
  touch "$out"
''
