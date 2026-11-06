# Check for template/buildaccel/shim.nix: shims around fake compilers and a
# fake launcher, executed inside the check sandbox; every case compares the
# full argv exactly.
{ pkgs, inputs }:
let
  bash = "${pkgs.bash}/bin/bash";

  # Prints its own path and every argument as <arg>, one per line.
  fakeCompiler = ''
    #!${bash}
    printf 'REAL %s\n' "$0"
    printf '<%s>\n' "$@"
  '';

  fakeCc =
    pkgs.runCommand "fake-cc-1.0"
      {
        passthru = {
          version = "1.0";
          isGNU = true;
          hardeningUnsupportedFlags = [ "fortify3" ];
        };
        meta.mainProgram = "gcc";
      }
      ''
        mkdir -p $out/bin $out/lib
        for c in gcc clang clang-21 x86_64-unknown-linux-gnu-gcc; do
          cat > $out/bin/$c <<'EOF'
        ${fakeCompiler}
        EOF
          chmod +x $out/bin/$c
        done
        for t in cpp ld gcc-ar .hidden-helper .gcc; do
          printf '#!${bash}\necho %s\n' "$t" > $out/bin/$t
          chmod +x $out/bin/$t
        done
        echo marker > $out/lib/marker
        echo meta > $out/.hidden-metadata
      '';

  fakeBintools = pkgs.runCommand "fake-bintools" { } ''
    mkdir -p $out/bin
    printf '#!${bash}\necho ld\n' > $out/bin/ld
    chmod +x $out/bin/ld
  '';

  # Records its argv on stdout, distinguishable from a direct compiler call.
  fakeLauncher = pkgs.runCommand "fake-buildaccel-launcher" { } ''
    mkdir -p $out/bin
    cat > $out/bin/buildaccel-launcher <<'EOF'
    #!${bash}
    printf 'LAUNCHER\n'
    printf '<%s>\n' "$@"
    EOF
    chmod +x $out/bin/buildaccel-launcher
  '';

  mkShim = import ../shim.nix {
    inherit pkgs;
    launcher = fakeLauncher;
  };
  shimGcc = mkShim {
    cc = fakeCc;
    bintools = fakeBintools;
    isClang = false;
  };
  shimClang = mkShim {
    cc = fakeCc;
    bintools = fakeBintools;
    isClang = true;
  };
in
assert shimGcc.isBuildAccelShim or false;
assert shimClang.isBuildAccelShim or false;
assert shimGcc.isCcache && shimClang.isCcache;
assert !shimGcc.isClang && shimClang.isClang;
assert shimGcc.isGNU;
assert shimGcc.version == "1.0";
assert shimGcc.meta.mainProgram == "gcc";
assert shimGcc.pname == "fake-cc";
assert shimGcc.hardeningUnsupportedFlags == [ "fortify3" ];
assert !(shimGcc ? hardeningUnsupportedFlagsByTargetPlatform);
assert shimGcc.name == "buildaccel-shim-fake-cc-1.0";
pkgs.runCommand "buildaccel-check-shim" { nativeBuildInputs = [ pkgs.diffutils ]; } ''
  set -u
  fail=0
  G=${shimGcc}/bin/gcc
  C=${shimClang}/bin/clang
  RG=${fakeCc}/bin/gcc
  RC=${fakeCc}/bin/clang
  B=-B${fakeBintools}/bin/

  # check NAME EXPECTED-LINE... -- COMMAND...
  check() {
    local name=$1
    shift
    local -a want=()
    while [[ $1 != -- ]]; do
      want+=("$1")
      shift
    done
    shift
    local got exp
    got=$("$@" 2>&1)
    exp=$(printf '%s\n' "''${want[@]}")
    if [[ $got == "$exp" ]]; then
      echo "ok   $name"
    else
      echo "FAIL $name"
      diff <(echo "$exp") <(echo "$got") || true
      fail=1
    fi
  }
  # assert NAME COMMAND...
  assert() {
    local name=$1
    shift
    if "$@"; then echo "ok   $name"; else echo "FAIL $name"; fail=1; fi
  }

  # Work in a directory reached through a symlink so pwd -P differs.
  mkdir -p "$TMPDIR/phys/work" "$TMPDIR/off" "$TMPDIR/on" "$TMPDIR/dir/enabled"
  echo 1 > "$TMPDIR/on/enabled"
  ln -s "$TMPDIR/phys/work" "$TMPDIR/link"
  phys=$(cd "$TMPDIR/phys/work" && pwd -P)
  cd "$TMPDIR/link"
  assert "cwd-is-logical-symlink" test "$PWD" != "$phys"
  D=-fdebug-compilation-dir=$phys

  # --- plain mode: BUILDACCEL_ROOT without enabled ---
  export BUILDACCEL_ROOT=$TMPDIR/off
  check gcc-compile "REAL $RG" "<-c>" "<t.c>" "<-o>" "<t.o>" "<$B>" -- \
    "$G" -c t.c -o t.o
  check clang-compile "REAL $RC" "<-c>" "<t.c>" "<$D>" -- \
    "$C" -c t.c
  check clang-file-dir-kept "REAL $RC" "<-c>" "<t.c>" "<-ffile-compilation-dir=.>" -- \
    "$C" -c t.c -ffile-compilation-dir=.
  check clang-debug-dir-kept "REAL $RC" "<-fdebug-compilation-dir=/x>" "<-c>" "<t.c>" -- \
    "$C" -fdebug-compilation-dir=/x -c t.c
  check gcc-version "REAL $RG" "<--version>" -- "$G" --version
  check clang-version "REAL $RC" "<--version>" -- "$C" --version
  check gcc-link "REAL $RG" "<t.o>" "<-o>" "<t>" -- "$G" t.o -o t
  check clang-link "REAL $RC" "<t.o>" "<-o>" "<t>" -- "$C" t.o -o t
  check gcc-no-args "REAL $RG" "<>" -- "$G"
  check gcc-odd-args "REAL $RG" "<-c>" "<a b.c>" "<>" "<*>" "<-o>" "<t.o>" "<$B>" -- \
    "$G" -c "a b.c" "" '*' -o t.o
  check gcc-cfoo-not-compile "REAL $RG" "<-cfoo>" "<t.c>" -- "$G" -cfoo t.c
  check clang-cfoo-not-compile "REAL $RC" "<-cfoo>" "<t.c>" -- "$C" -cfoo t.c
  check gcc-double-c "REAL $RG" "<-c>" "<-c>" "<t.c>" "<$B>" -- "$G" -c -c t.c
  check clang-double-c "REAL $RC" "<-c>" "<-c>" "<t.c>" "<$D>" -- "$C" -c -c t.c
  check prefixed-gcc-shimmed "REAL ${fakeCc}/bin/x86_64-unknown-linux-gnu-gcc" "<-c>" "<t.c>" "<$B>" -- \
    ${shimGcc}/bin/x86_64-unknown-linux-gnu-gcc -c t.c
  check clang-21-shimmed "REAL ${fakeCc}/bin/clang-21" "<-c>" "<t.c>" "<$D>" -- \
    ${shimClang}/bin/clang-21 -c t.c

  # --- enabled is a directory: not accelerated ---
  export BUILDACCEL_ROOT=$TMPDIR/dir
  check enabled-dir-gcc "REAL $RG" "<-c>" "<t.c>" "<$B>" -- "$G" -c t.c

  # --- accelerated mode: enabled is a regular file ---
  export BUILDACCEL_ROOT=$TMPDIR/on
  check on-gcc-compile "LAUNCHER" "<$RG>" "<-c>" "<t.c>" "<-o>" "<t.o>" "<$B>" -- \
    "$G" -c t.c -o t.o
  check on-clang-compile "LAUNCHER" "<$RC>" "<-c>" "<t.c>" "<$D>" -- \
    "$C" -c t.c
  check on-clang-file-dir-kept "LAUNCHER" "<$RC>" "<-c>" "<t.c>" "<-ffile-compilation-dir=.>" -- \
    "$C" -c t.c -ffile-compilation-dir=.
  check on-gcc-odd-args "LAUNCHER" "<$RG>" "<-c>" "<a b.c>" "<>" "<*>" "<$B>" -- \
    "$G" -c "a b.c" "" '*'
  check on-gcc-double-c "LAUNCHER" "<$RG>" "<-c>" "<-c>" "<t.c>" "<$B>" -- "$G" -c -c t.c
  check on-gcc-version "REAL $RG" "<--version>" -- "$G" --version
  check on-clang-link "REAL $RC" "<t.o>" "<-o>" "<t>" -- "$C" t.o -o t
  check on-gcc-cfoo "REAL $RG" "<-cfoo>" "<t.c>" -- "$G" -cfoo t.c

  # --- layout of the shim output ---
  for n in gcc x86_64-unknown-linux-gnu-gcc; do
    assert "script-$n" test -f ${shimGcc}/bin/$n -a ! -L ${shimGcc}/bin/$n -a -x ${shimGcc}/bin/$n
  done
  assert "shebang" test "$(head -n1 "$G")" = "#!${bash}"
  for n in cpp ld gcc-ar .hidden-helper .gcc; do
    assert "symlink-$n" test -L ${shimGcc}/bin/$n -a "$(readlink ${shimGcc}/bin/$n)" = ${fakeCc}/bin/$n
  done
  assert "symlink-lib" test -L ${shimGcc}/lib -a "$(readlink ${shimGcc}/lib)" = ${fakeCc}/lib
  assert "symlink-.hidden-metadata" test -L ${shimGcc}/.hidden-metadata -a "$(readlink ${shimGcc}/.hidden-metadata)" = ${fakeCc}/.hidden-metadata
  assert "lib-marker" test "$(cat ${shimGcc}/lib/marker)" = marker
  assert "top-entries" test "$(ls -A ${shimGcc})" = "$(ls -A ${fakeCc})"
  assert "bin-entries" test "$(ls -A ${shimGcc}/bin)" = "$(ls -A ${fakeCc}/bin)"
  assert "top-entries-count" test "$(ls -A ${shimGcc} | wc -l)" -eq 3

  if ((fail)); then
    echo "buildaccel shim check FAILED"
    exit 1
  fi
  echo ok > $out
''
