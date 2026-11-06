{ pkgs, inputs }:
let
  server = import ../server-pkgs.nix { inherit pkgs; };
  lib = pkgs.lib;
  gccRoot = "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-gcc-15.3.0";
  gcc = "${gccRoot}/bin/gcc";
  clangRoot = "/nix/store/cccccccccccccccccccccccccccccccc-clang-21";
  clang = "${clangRoot}/bin/clang";
  binutils = "/nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-binutils-wrapper";
  cases = [
    {
      name = "gcc";
      args = [
        "-c"
        "x.i"
        "-o"
        "y.o"
        "-B${binutils}/bin/"
      ];
      roots = [
        gccRoot
        binutils
      ];
    }
    {
      name = "non-store";
      compiler = "/usr/bin/gcc";
      status = 111;
    }
    {
      name = "non-compiler";
      compiler = "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-bash/bin/bash";
      status = 111;
    }
    {
      name = "short-hash";
      compiler = "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-gcc/bin/gcc";
      status = 111;
    }
    {
      name = "uppercase-hash";
      compiler = "/nix/store/Aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-gcc/bin/gcc";
      status = 111;
    }
    {
      name = "trailing-slash";
      compiler = "${gcc}/";
      status = 111;
    }
    {
      name = "compiler-parent";
      compiler = "${gccRoot}/bin/../bin/gcc";
      status = 111;
    }
    {
      name = "cwd";
      args = [
        "-c"
        "cwd.i"
      ];
      cwd = "/build/source/build";
    }
    {
      name = "cwd-parent";
      args = [
        "-c"
        "parent.i"
      ];
    }
    {
      name = "cwd-outside";
      args = [
        "-c"
        "outside.i"
      ];
    }
    {
      name = "cwd-sixth-line";
      args = [
        "-c"
        "sixth.i"
      ];
    }
    {
      name = "cwd-missing-file";
      args = [
        "-c"
        "missing.i"
      ];
    }
    {
      name = "clang";
      compiler = clang;
      roots = [ clangRoot ];
      args = [
        "-c"
        "x.ii"
      ];
      appended = [ "-Wno-unused-command-line-argument" ];
    }
    {
      name = "clang-version";
      compiler = "${clangRoot}/bin/clang-21";
      roots = [ clangRoot ];
      appended = [ "-Wno-unused-command-line-argument" ];
    }
    {
      name = "cross-gcc";
      compiler = "${gccRoot}/bin/aarch64-linux-gnu-gcc";
    }
    {
      name = "literal-arguments";
      args = [
        "with spaces"
        "$(touch /tmp/pwned)"
        ";"
        "line\nbreak"
        ""
      ];
    }
    {
      name = "distinct-embedded-roots";
      args = [
        "-B${binutils}/bin/"
        "-B${binutils}/bin/"
        "-fmacro-prefix-map=${clangRoot}/x=${binutils}/y"
      ];
      roots = [
        gccRoot
        binutils
        clangRoot
      ];
    }
    # clang's joined `-Xclang=<arg>` forwarding alias must be refused with
    # exit 111.
    {
      name = "refuse-xclang-joined-load";
      compiler = clang;
      args = [
        "-c"
        "x.i"
        "-Xclang=-load"
        "-Xclang=/tmp/x.so"
      ];
      status = 111;
    }
    # gcc's separate `-specs <file>` and long `--specs=`/`--specs <file>`
    # spellings (gcc/common.opt aliases) must be refused.
    {
      name = "refuse-specs-separate";
      args = [
        "-c"
        "x.i"
        "-specs"
        "/tmp/evil.specs"
      ];
      status = 111;
    }
    {
      name = "refuse-specs-long-joined";
      args = [
        "-c"
        "x.i"
        "--specs=/tmp/evil.specs"
      ];
      status = 111;
    }
    {
      name = "refuse-specs-long-separate";
      args = [
        "-c"
        "x.i"
        "--specs"
        "/tmp/evil.specs"
      ];
      status = 111;
    }
    # gcc's `--`->`-f` driver remap (gcc/opts-common.cc option_map) aliases
    # -fplugin as --plugin.
    {
      name = "refuse-plugin-long";
      args = [
        "-c"
        "x.i"
        "--plugin=/tmp/x.so"
      ];
      status = 111;
    }
    # clang's `-mllvm` forwards to LLVM, which can load pass plugins.
    {
      name = "refuse-mllvm-separate";
      compiler = clang;
      args = [
        "-c"
        "x.ii"
        "-mllvm"
        "-load=/tmp/x.so"
      ];
      status = 111;
    }
    {
      name = "refuse-mllvm-joined";
      compiler = clang;
      args = [
        "-c"
        "x.ii"
        "-mllvm=-load=/tmp/x.so"
      ];
      status = 111;
    }
  ]
  ++
    map
      (flag: {
        name = "refuse-${flag}";
        args = [ flag ];
        status = 111;
      })
      [
        "-fplugin=x.so"
        "-fplugin-arg-x=y"
        "-fpass-plugin=x.so"
        "-load"
        "-Xclang"
        "-wrapper"
        "-specs=x"
        "--config=x"
        "--config"
        "@rsp"
        "-B/tmp/"
        "-B"
        "-B/nix/store/../tmp/"
        "-B${binutils}/../bin/"
        "-fprofile-use=x"
        "-fprofile-instr-use=x"
        "-fprofile-sample-use=x"
        "-fsanitize-ignorelist=x"
        "-fsanitize-blacklist=x"
        "-Xclang=-load"
        "-Xclang=/tmp/x.so"
        "-mllvm=-load=x"
        "--plugin=x.so"
        "--pass-plugin=x.so"
        "--specs=x"
        "--wrapper=x"
        "-load=x"
        "--profile-use=x"
        "--profile-instr-use=x"
        "--profile-sample-use=x"
        "--sanitize-ignorelist=x"
        "--sanitize-blacklist=x"
      ];
  runCase =
    case:
    let
      status = case.status or 0;
      argv = [ (case.compiler or gcc) ] ++ (case.args or [ ]);
      expectedArgv = argv ++ (case.appended or [ ]);
      # Literal `$(...)` arguments are deliberate; scope SC2016 to the commands carrying them.
      literalDollar = lib.any (a: lib.hasInfix "$(" a) argv;
      allowLiteral = lib.optionalString literalDollar "# shellcheck disable=SC2016\n";
    in
    ''
      : > expected
      ${lib.optionalString (status == 0) ''
        {
          printf 'realise %q\n' ${lib.escapeShellArgs (case.roots or [ gccRoot ])}
          printf 'cwd %q\n' ${if case ? cwd then lib.escapeShellArg case.cwd else ''"$PWD"''}
          printf 'argv'
          ${allowLiteral}printf ' %q' ${lib.escapeShellArgs expectedArgv}
          printf '\n'
        } >> expected
      ''}
      status=0
      ${allowLiteral}BUILDACCEL_RESOLVER_DRYRUN=1 ${server.resolver}/bin/buildaccel-resolver \
        ${lib.escapeShellArgs argv} > actual 2> errors || status=$?
      if [[ $status != ${toString status} ]] || ! cmp -s expected actual || [[ -s errors ]]; then
        printf 'FAIL %s: expected status %s, got %s\n' ${lib.escapeShellArg case.name} ${toString status} "$status"
        diff -u expected actual || true
        cat errors
        exit 1
      fi
      printf 'PASS %s exit=%s\n' ${lib.escapeShellArg case.name} "$status"
      cat actual
    '';
in
pkgs.runCommand "buildaccel-resolver-check" { __darwinAllowLocalNetworking = true; } ''
    ${server.distccPatched}/bin/distccd --version
    printf '%s\n' '# 0 "input.c"' '# 1 "/build/source/build//"' > cwd.i
    printf '%s\n' '# 1 "/build/../etc//"' > parent.i
    printf '%s\n' '# 1 "/etc/source//"' > outside.i
    printf '%s\n' a b c d e '# 1 "/build/source/build//"' > sixth.i
    ${lib.concatMapStringsSep "\n" runCase cases}
    test ! -e /tmp/pwned

    # A refused compiler path with control characters must reach logger as a
    # single line (no split or forged log entries). Not dry-run, so the
    # resolver really calls logger; a stub logger on PATH records the message.
    mkdir -p stub-bin
    cat > stub-bin/logger <<'LOGGER'
  #!${pkgs.runtimeShell}
  printf '%s' "$3" > "$BUILDACCEL_LOGGER_RECORD"
  LOGGER
    chmod +x stub-bin/logger
    log_status=0
    BUILDACCEL_LOGGER_RECORD="$PWD/logger-msg" PATH="$PWD/stub-bin:$PATH" \
      ${server.resolver}/bin/buildaccel-resolver \
      $'/etc/evil\nbuildaccel-resolver: ok compiler=forged\r\033[2J' \
      > /dev/null 2>&1 || log_status=$?
    if [[ $log_status != 111 ]]; then
      echo "FAIL log-single-line: expected status 111, got $log_status"
      exit 1
    fi
    if [[ ! -f logger-msg ]] || [[ $(wc -l < logger-msg) != 0 ]] \
      || [[ $(tr -d '[:print:]' < logger-msg | wc -c) != 0 ]] \
      || ! grep -qxF 'refused reason=compiler compiler=/etc/evil?buildaccel-resolver: ok compiler=forged??[2J' logger-msg; then
      echo 'FAIL log-single-line: logger message was not sanitized'
      od -c logger-msg || true
      exit 1
    fi
    echo 'PASS log-single-line'

    # End-to-end daemon test on loopback. Proves both patch hunks in one run:
    # daemon.c lets distccd start with DISTCC_NIX_RESOLVER set (skips the
    # startup masquerade-whitelist check), and serve.c prepends the resolver
    # to the job argv. The resolver here is a stub that records its argv and
    # then execs the client's compiler, so a real object is produced remotely.
    export HOME="$PWD/home"
    mkdir -p "$HOME" distccd-tmp
    record="$PWD/stub-argv"
    cat > stub.sh <<'STUB'
  #!${pkgs.runtimeShell}
  printf '%s\n' "$@" > "$BUILDACCEL_STUB_RECORD"
  exec "$@"
  STUB
    chmod +x stub.sh

    cc=${pkgs.stdenv.cc}/bin/cc
    printf 'int main(void){return 0;}\n' > t.c

    daemon_pid=
    cleanup() {
      if [ -n "$daemon_pid" ]; then
        kill "$daemon_pid" 2>/dev/null || true
        wait "$daemon_pid" 2>/dev/null || true
      fi
      return 0
    }
    trap cleanup EXIT

    started=0
    port=0
    for _ in 1 2 3 4 5; do
      port=$(( (RANDOM % 20000) + 20000 ))
      BUILDACCEL_STUB_RECORD="$record" \
      DISTCC_NIX_RESOLVER="$PWD/stub.sh" \
      TMPDIR="$PWD/distccd-tmp" \
        ${server.distccPatched}/bin/distccd --daemon --no-detach \
          --listen 127.0.0.1 --port "$port" --allow 127.0.0.1/32 \
          --log-stderr --log-level info --jobs 2 > "distccd-$port.log" 2>&1 &
      daemon_pid=$!
      # Bounded readiness wait: ready only when the port accepts a connection.
      ready=0
      for _ in $(seq 1 100); do
        if ! kill -0 "$daemon_pid" 2>/dev/null; then break; fi
        if (exec 3<>/dev/tcp/127.0.0.1/"$port") 2>/dev/null; then
          exec 3>&- 3<&-
          ready=1
          break
        fi
        sleep 0.1
      done
      if [ "$ready" = 1 ]; then
        started=1
        break
      fi
      kill "$daemon_pid" 2>/dev/null || true
      wait "$daemon_pid" 2>/dev/null || true
      daemon_pid=
    done

    if [ "$started" != 1 ]; then
      echo "FAIL daemon-e2e: patched distccd did not become ready"
      cat "distccd-$port.log" 2>/dev/null || true
      exit 1
    fi

    # Daemon must be alive at the moment the compile is issued.
    if ! kill -0 "$daemon_pid" 2>/dev/null; then
      echo "FAIL daemon-e2e: daemon exited before the compile"
      cat "distccd-$port.log"
      exit 1
    fi

    compile_status=0
    DISTCC_HOSTS="127.0.0.1:$port" DISTCC_FALLBACK=0 TMPDIR="$PWD" \
      timeout 60 ${server.distccPatched}/bin/distcc "$cc" -c t.c -o t.o \
      > distcc.log 2>&1 || compile_status=$?

    daemon_alive_after=0
    kill -0 "$daemon_pid" 2>/dev/null && daemon_alive_after=1

    if [ "$compile_status" != 0 ]; then
      echo "FAIL daemon-e2e: remote compile exited $compile_status"
      echo '--- distcc.log'; cat distcc.log
      echo "--- distccd-$port.log"; cat "distccd-$port.log"
      exit 1
    fi
    if [ "$daemon_alive_after" != 1 ]; then
      echo "FAIL daemon-e2e: daemon was not running after the compile"
      cat "distccd-$port.log"
      exit 1
    fi
    if [ ! -f "$record" ]; then
      echo "FAIL daemon-e2e: stub resolver recorded no argv"
      cat "distccd-$port.log"
      exit 1
    fi
    argv0=$(head -1 "$record")
    if [ "$argv0" != "$cc" ] && [ "$(basename "$argv0")" != cc ]; then
      echo "FAIL daemon-e2e: stub argv[0] is not the compiler ($argv0)"
      cat "$record"
      exit 1
    fi
    if ! grep -qx -- '-c' "$record"; then
      echo "FAIL daemon-e2e: stub argv missing -c"
      cat "$record"
      exit 1
    fi
    if [ ! -f t.o ]; then
      echo "FAIL daemon-e2e: object t.o was not produced"
      exit 1
    fi

    cleanup
    trap - EXIT
    if kill -0 "$daemon_pid" 2>/dev/null; then
      echo "FAIL daemon-e2e: daemon survived kill"
      exit 1
    fi
    daemon_pid=
    printf 'PASS daemon-e2e port=%s argv0=%s\n' "$port" "$argv0"

    touch "$out"
''
