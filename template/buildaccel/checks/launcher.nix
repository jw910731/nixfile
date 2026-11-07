# Runs the launcher and bridge with real ccache, distcc and socat against a
# fake compiler, a temporary BUILDACCEL_ROOT and temporary per-build files.
# No network: "servers" are local socat listeners on unix sockets (one closes
# every connection, one runs distccd --inetd); background helpers are killed
# and waited for before the check ends; no sleeps.
{ pkgs, inputs }:
let
  launcher = import ../launcher.nix { inherit pkgs; };
in
pkgs.runCommand "buildaccel-check-launcher"
  {
    passthru = { inherit launcher; };
  }
  ''
    set -euo pipefail
    L=${launcher}/bin/buildaccel-launcher
    BR=${launcher}/bin/buildaccel-bridge
    CU=${pkgs.coreutils}/bin
    SOCAT=${pkgs.socat}/bin/socat
    DISTCCD=${pkgs.distcc}/bin/distccd
    CCACHE=${pkgs.ccache}/bin/ccache
    BASH=${pkgs.bash}/bin/bash
    export PATH=$CU:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin
    export HOME=$TMPDIR/home
    mkdir -p "$HOME"
    T=$TMPDIR
    R=$T/r
    W=$T/w
    export BUILDACCEL_ROOT=$R
    export BUILDACCEL_LOCAL_CORES=2
    unset BUILDACCEL_SYSTEM || true
    mkdir -p "$R/sock" "$R/state/distcc" "$R/health" "$W" "$T/cache"

    LISTENERS=()
    cleanup() {
      local p
      for p in "''${LISTENERS[@]}"; do kill "$p" 2>/dev/null || true; done
      wait || true
      chmod -R u+w "$T" 2>/dev/null || true
    }
    trap cleanup EXIT

    fail() { echo "FAIL: $*" >&2; exit 1; }
    eq() { [ "$1" = "$2" ] || fail "$3: got [$1] want [$2]"; echo "ok: $3 = [$1]"; }

    # start_listener <socket> <socat right-hand address>: waits on socat's own
    # "listening on" notice (read from a fifo, bounded by read -t 10).
    NL=0
    start_listener() {
      local fifo line fd up=0
      NL=$((NL + 1))
      fifo=$T/fifo.$NL
      mkfifo "$fifo"
      "$SOCAT" -d -d "UNIX-LISTEN:$1,fork" "$2" 2>"$fifo" &
      LISTENERS+=("$!")
      exec {fd}<"$fifo"
      while IFS= read -r -t 10 line <&"$fd"; do
        case $line in *"listening on"*) up=1; break ;; esac
      done
      [ "$up" = 1 ] || fail "listener on $1 did not start"
      cat <&"$fd" >/dev/null &
      LISTENERS+=("$!")
      exec {fd}<&-
    }

    # Fake compiler: honours -E and -c -o; records argv and the distcc/ccache
    # environment it was started with.
    FC=$T/fc/gcc
    FCLOG=$T/fc.log
    FCENV=$T/fc.env
    FCENV2=$T/fc.env2
    DISTCC=${pkgs.distcc}/bin/distcc
    mkdir -p "$T/fc"
    cat >"$FC" <<EOF
    #!$BASH
    printf ' %s \n' "\$*" >>"$FCLOG"
    mode="" out="" src=""
    hosts="\''${DISTCC_HOSTS-unset}"
    while [ \$# -gt 0 ]; do
      case \$1 in
        -E) mode=E ;;
        -c) mode=c ;;
        -o) out=\$2; shift ;;
        -*) ;;
        *) src=\$1 ;;
      esac
      shift
    done
    if [ "\$mode" = c ]; then
      printf 'hosts=%s ssh=%s nrc=%s fb=%s bo=%s io=%s\n' "\$hosts" "\''${DISTCC_SSH-unset}" \
        "\''${DISTCC_NO_REWRITE_CROSS-unset}" "\''${DISTCC_FALLBACK-unset}" \
        "\''${DISTCC_BACKOFF_PERIOD-unset}" "\''${DISTCC_IO_TIMEOUT-unset}" >>"$FCENV"
      printf 'umask=%s cfg=%s chk=%s tmp=%s slog=%s pre=%s precpp=%s ddir=%s dlog=%s dv=%s\n' "\$(umask)" \
        "\''${CCACHE_CONFIGPATH-unset}" "\''${CCACHE_COMPILERCHECK-unset}" "\''${CCACHE_TEMPDIR-unset}" \
        "\''${CCACHE_STATSLOG-unset}" "\''${CCACHE_PREFIX-unset}" "\''${CCACHE_PREFIX_CPP-unset}" \
        "\''${DISTCC_DIR-unset}" "\''${DISTCC_LOG-unset}" "\''${DISTCC_VERBOSE-unset}" >>"$FCENV2"
      [ -n "\$out" ] || out=\''${src%.*}.o
      { echo FAKEOBJ; cat "\$src"; } >"\$out"
    elif [ "\$mode" = E ]; then
      if [ -n "\$out" ]; then cat "\$src" >"\$out"; else cat "\$src"; fi
    fi
    EOF
    chmod +x "$FC"
    : >"$FCLOG"
    : >"$FCENV"
    ncompiles() { grep -c -e ' -c ' "$FCLOG" || true; }

    NOW=$(date +%s)
    fresh() { echo "ok $(( $(date +%s) - 5 ))" >"$R/health/$1"; }
    stale() { echo "ok $(( $(date +%s) - 600 ))" >"$R/health/$1"; }

    cat >"$R/ccache.conf" <<EOF
    cache_dir = $T/cache
    max_size = 1G
    direct_mode = true
    depend_mode = false
    hash_dir = true
    compression = true
    umask = 007
    hard_link = false
    file_clone = false
    stats = true
    EOF

    reset_build() { rm -rf "$T/.buildaccel" "$R/state/distcc"; mkdir -p "$T/.buildaccel" "$R/state/distcc"; }
    run_cc() {
      local rc=0
      (cd "$W" && "$L" "$FC" "$@") >"$T/out" 2>"$T/err" || rc=$?
      [ "$rc" = 0 ] || fail "compile $* exited $rc: $(cat "$T/err")"
      [ ! -s "$T/out" ] || fail "compile $* wrote stdout: $(cat "$T/out")"
      [ ! -s "$T/err" ] || fail "compile $* wrote stderr: $(cat "$T/err")"
    }
    last_stat() { tail -n 1 "$T/.buildaccel/stats" | cut -d' ' -f1,2; }
    # distcc log of the current build
    cclogs() { cat "$T"/.buildaccel/inv/*/distcc.log 2>/dev/null || true; }
    inv_norm() { sed -E "s#$T/.buildaccel/inv/[A-Za-z0-9]{8}#INV#g"; }
    src() { echo "int $1(void) { return $2; }" >"$W/$1.c"; touch -d "@$((NOW - 100))" "$W/$1.c"; }
    probe() {
      local o
      o=$("$L" --probe 2>"$T/perr") || fail "--probe exited non-zero"
      [ ! -s "$T/perr" ] || fail "--probe wrote stderr"
      printf '%s' "$o"
    }
    ccstat() { CCACHE_CONFIGPATH=$R/ccache.conf "$CCACHE" --print-stats | grep "^$1"$'\t' | cut -f2; }

    echo "== A: no enabled/servers -> cache mode, second call is a ccache hit"
    reset_build
    src a 1
    run_cc -c a.c -o a.o
    eq "$(last_stat)" "cache no-server" "A first stats line"
    run_cc -c a.c -o a.o
    eq "$(last_stat)" "cache no-server" "A second stats line"
    eq "$(ncompiles)" "1" "A fake compiler -c runs"
    eq "$(head -n 1 "$W/a.o")" "FAKEOBJ" "A object produced"
    CCACHE_CONFIGPATH=$R/ccache.conf "$CCACHE" -s
    eq "$(( $(ccstat direct_cache_hit) + $(ccstat preprocessed_cache_hit) ))" "1" "A ccache hits (ccache --print-stats)"
    eq "$(ccstat cache_miss)" "1" "A ccache misses (ccache --print-stats)"
    eq "$(tail -n 1 "$FCENV")" "hosts=--localslots=2 --localslots_cpp=2 localhost/2 ssh=unset nrc=unset fb=unset bo=unset io=unset" "A local DISTCC env"
    cclogs | grep -q "^distcc\[[0-9]*\] exec on localhost: $FC .*-c" || fail "A: distcc did not run the compile locally"
    a2=$(tail -n 1 "$FCENV2" | inv_norm)
    echo "observed compiler env under ccache: $a2"
    eq "''${a2#umask=* }" "cfg=$R/ccache.conf chk=string:$FC tmp=$T/.buildaccel/ccache-tmp slog=INV/ccache-stats.log pre=$L precpp=$DISTCC ddir=$R/state/distcc dlog=INV/distcc.log dv=1" "A launcher exports (compile prefix = launcher prefix mode)"
    echo "-- inherited CCACHE_DISABLE/DISTCC_HOSTS are ignored"
    (export CCACHE_DISABLE=1 DISTCC_HOSTS=bogus-host; run_cc -c a.c -o a.o)
    eq "$(ncompiles)" "1" "A3 still a cache hit"
    eq "$("$L" --summary)" "invocations=3 ccache-hits=2 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=no-server:3" "A summary from real logs"

    echo "== B: server listed, no socket -> no-server"
    touch "$R/enabled"
    export BUILDACCEL_SYSTEM=aarch64-linux
    printf 'qa-a 4 aarch64-linux\n' >"$R/servers"
    fresh qa-a
    eq "$(probe)" "0" "B probe without socket"
    reset_build
    src b 2
    run_cc -c b.c -o b.o
    eq "$(last_stat)" "cache no-server" "B stats line"

    echo "== C: socket + down / stale ok -> no-server"
    start_listener "$R/sock/qa-a" "EXEC:$CU/true"
    echo "down $((NOW - 5)) connect-refused" >"$R/health/qa-a"
    eq "$(probe)" "0" "C probe health down"
    reset_build
    run_cc -c b.c -o b.o
    eq "$(last_stat)" "cache no-server" "C stats line health down"
    stale qa-a
    eq "$(probe)" "0" "C probe health ok 600s old"
    reset_build
    run_cc -c b.c -o b.o
    eq "$(last_stat)" "cache no-server" "C stats line health stale"

    echo "== D: fresh ok + socket -> probe prints slots"
    fresh qa-a
    eq "$(probe)" "4" "D probe one server"
    start_listener "$R/sock/qa-b" "EXEC:$CU/true"
    start_listener "$R/sock/qa-c" "EXEC:$CU/true"
    printf 'qa-a 4 aarch64-linux\nqa-b 3 aarch64-linux\nqa-c 5 x86_64-linux\nqa-a 4 aarch64-linux\n' >"$R/servers"
    fresh qa-b
    fresh qa-c
    eq "$(probe)" "7" "D probe two aarch64 servers, duplicate line ignored"
    eq "$(BUILDACCEL_SYSTEM=x86_64-linux "$L" --probe)" "5" "D probe x86_64-linux"
    stale qa-b
    eq "$(probe)" "4" "D probe with qa-b stale"
    printf 'qa-a 1025 aarch64-linux\n' >"$R/servers"
    eq "$(probe)" "1025" "D probe one server with 1025 slots (no cap)"
    fresh qa-b
    printf 'qa-a 700 aarch64-linux\nqa-b 600 aarch64-linux\n' >"$R/servers"
    eq "$(probe)" "1300" "D probe sum above 1024 (no cap)"
    echo "-- slot contract: canonical positive decimal, 1 <= v <= 9223372036854775807, sum must not overflow"
    fresh qa-a
    fresh qa-b
    slots_probe() {
      printf '%s\n' "$@" >"$R/servers"
      probe
    }
    eq "$(slots_probe 'qa-a 10000000000 aarch64-linux')" "10000000000" "D slots 10000000000"
    eq "$(slots_probe 'qa-a 1000000000000000000 aarch64-linux')" "1000000000000000000" "D slots 19 digits below max"
    eq "$(slots_probe 'qa-a 9223372036854775807 aarch64-linux')" "9223372036854775807" "D slots int64 max"
    eq "$(slots_probe 'qa-a 9223372036854775808 aarch64-linux')" "0" "D slots int64 max + 1"
    eq "$(slots_probe 'qa-a 9300000000000000000 aarch64-linux')" "0" "D slots 19 digits above max"
    eq "$(slots_probe 'qa-a 12345678901234567890 aarch64-linux')" "0" "D slots 20 digits"
    eq "$(slots_probe 'qa-a 9223372036854775807 aarch64-linux' 'qa-b 1 aarch64-linux')" "0" "D slots sum overflow"
    eq "$(slots_probe 'qa-a 9223372036854775806 aarch64-linux' 'qa-b 1 aarch64-linux')" "9223372036854775807" "D slots sum exactly int64 max"
    eq "$(slots_probe 'qa-a 1025 aarch64-linux')" "1025" "D slots 1025"
    eq "$(slots_probe 'qa-a 700 aarch64-linux' 'qa-b 600 aarch64-linux')" "1300" "D slots 700 + 600"
    for s in 04 1.5 -3 +3 0 00 1e3 0x10 ""; do
      eq "$(slots_probe "qa-a $s aarch64-linux")" "0" "D slots [$s]"
    done
    rm "$R/enabled"
    eq "$(probe)" "0" "D probe without enabled"
    touch "$R/enabled"

    echo "== E: remote attempt that fails (server closes) -> local fallback"
    printf 'qa-a 4 aarch64-linux\n' >"$R/servers"
    fresh qa-a
    reset_build
    src e 5
    run_cc -c e.c -o e.o
    eq "$(last_stat)" "remote ok" "E stats line"
    eq "$(head -n 1 "$W/e.o")" "FAKEOBJ" "E object produced by fallback"
    eq "$(tail -n 1 "$FCENV")" "hosts=--localslots=2 --localslots_cpp=2 @qa-a/4,lzo ssh=$BR nrc=1 fb=1 bo=60 io=120" "E remote DISTCC env (no localhost entry)"
    eq "$("$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=0 remote-failed=1 local=1 unaccounted=0 hosts= skipped=" "E summary from real logs"
    echo "-- compile mode uses the same slot validation as --probe"
    # cc_hosts <id> <servers lines...>: a fresh source per call, so ccache
    # never hits and the fake compiler records this call's environment.
    cc_hosts() {
      local id=$1
      shift
      printf '%s\n' "$@" >"$R/servers"
      reset_build
      src "e2$id" "$id"
      run_cc -c "e2$id.c" -o "e2$id.o"
      [ "$(head -n 1 "$W/e2$id.o")" = FAKEOBJ ] || fail "E2 $id: no object"
      printf '%s|%s' "$(last_stat)" "$(tail -n 1 "$FCENV" | sed 's/ ssh=.*//' | inv_norm)"
    }
    fresh qa-a
    fresh qa-b
    eq "$(cc_hosts 1 'qa-a 10000000000 aarch64-linux')" "remote ok|hosts=--localslots=2 --localslots_cpp=2 @qa-a/2147483647,lzo" "E2 10000000000 slots: remote, distcc int clamp"
    eq "$(cc_hosts 2 'qa-a 2147483647 aarch64-linux')" "remote ok|hosts=--localslots=2 --localslots_cpp=2 @qa-a/2147483647,lzo" "E2 INT_MAX slots unchanged"
    eq "$(cc_hosts 3 'qa-a 1025 aarch64-linux' 'qa-b 3 aarch64-linux')" "remote ok|hosts=--localslots=2 --localslots_cpp=2 @qa-a/1025,lzo @qa-b/3,lzo" "E2 two servers"
    eq "$(cc_hosts 4 'qa-a 9223372036854775807 aarch64-linux' 'qa-b 1 aarch64-linux')" "cache no-server|hosts=--localslots=2 --localslots_cpp=2 localhost/2" "E2 sum overflow -> no-server"
    eq "$(cc_hosts 5 'qa-a 9223372036854775808 aarch64-linux')" "cache no-server|hosts=--localslots=2 --localslots_cpp=2 localhost/2" "E2 int64 max + 1 -> no-server"
    eq "$(cc_hosts 6 'qa-a 04 aarch64-linux')" "cache no-server|hosts=--localslots=2 --localslots_cpp=2 localhost/2" "E2 non-canonical 04 -> no-server"

    echo "== F: remote success through distccd --inetd behind the bridge"
    start_listener "$R/sock/qa-d" "EXEC:$DISTCCD --inetd --enable-tcp-insecure --log-file=$T/distccd.log"
    printf 'qa-d 2 aarch64-linux\n' >"$R/servers"
    fresh qa-d
    reset_build
    src f 6
    before=$(ncompiles)
    run_cc -c f.c -o f.o
    eq "$(last_stat)" "remote ok" "F stats line"
    eq "$(head -n 1 "$W/f.o")" "FAKEOBJ" "F object returned by the server"
    eq "$(( $(ncompiles) - before ))" "1" "F exactly one compile (on the server)"
    eq "$("$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=1 remote-failed=0 local=0 unaccounted=0 hosts=qa-d:1 skipped=" "F summary from real logs"

    echo "== G: -march=native is never offered to a server"
    printf 'qa-a 4 aarch64-linux\n' >"$R/servers"
    fresh qa-a
    reset_build
    src g 7
    run_cc -march=native -c g.c -o g.o
    eq "$(last_stat)" "cache deny:-march=native" "G stats line"
    cclogs | grep -q "^distcc\[[0-9]*\] exec on localhost: $FC .*-march=native" || fail "G: distcc did not run the fake compiler locally"
    grep -q -- "-march=native -c g.c -o g.o" "$FCLOG" || fail "G: fake compiler did not run"
    eq "$(tail -n 1 "$FCENV")" "hosts=--localslots=2 --localslots_cpp=2 localhost/2 ssh=unset nrc=unset fb=unset bo=unset io=unset" "G local DISTCC env"
    if cclogs | grep -q "exec on @"; then fail "G: offered to a server"; fi
    "$L" --summary | grep -q " remote-failed=0 local=1 " || fail "G summary"
    echo "-- every deny-list pattern is kept local (a usable server is present)"
    : >"$W/rsp"
    for flag in -march=native -mcpu=native -mtune=native -fplugin=x.so -fpass-plugin=x.so \
      -fprofile-use -fprofile-instr-use=x -fprofile-sample-use=x -fsanitize=address \
      -fsanitize-ignorelist=x -include-pch -fmodules -fmodules-cache-path=x -save-temps \
      -save-temps=obj -Xclang -specs=x -wrapper --config=x @rsp; do
      reset_build
      (cd "$W" && "$L" "$FC" -c g.c -o g.o "$flag") >/dev/null 2>&1 || true
      eq "$(last_stat)" "cache deny:$flag" "G deny $flag"
      if cclogs | grep -q "exec on @"; then fail "G: $flag offered to a server"; fi
    done
    for flag in -march=armv8-a -fsanitize-coverage=trace-pc -fprofile-generate -mcpu=cortex-a76; do
      reset_build
      (cd "$W" && "$L" "$FC" -c g.c -o g.o "$flag") >/dev/null 2>&1 || true
      eq "$(last_stat)" "remote ok" "G not denied $flag"
    done

    echo "-- local slots: BUILDACCEL_LOCAL_CORES canonical 1..INT_MAX, else nproc"
    NPROC=$(nproc)
    rm "$R/enabled"
    cores_hosts() {
      reset_build
      src "k$1" "$1"
      (export BUILDACCEL_LOCAL_CORES="$2"; run_cc -c "k$1.c" -o "k$1.o")
      tail -n 1 "$FCENV" | sed 's/ ssh=.*//'
    }
    eq "$(cores_hosts 1 10000)" "hosts=--localslots=10000 --localslots_cpp=10000 localhost/10000" "K cores 10000"
    eq "$(cores_hosts 2 2147483647)" "hosts=--localslots=2147483647 --localslots_cpp=2147483647 localhost/2147483647" "K cores INT_MAX"
    for v in 0 2147483648 abc 04 -2 ""; do
      NK=$((''${NK:-2} + 1))
      eq "$(cores_hosts "$NK" "$v")" "hosts=--localslots=$NPROC --localslots_cpp=$NPROC localhost/$NPROC" "K cores [$v] -> nproc"
    done

    echo "-- DISTCC_DIR fallback and umask without ccache"
    reset_build
    chmod 0555 "$R/state/distcc"
    src k9 9
    run_cc -c k9.c -o k9.o
    eq "$(tail -n 1 "$FCENV2" | sed 's/^umask=[0-9]* cfg=.* ddir=//; s/ dlog=.*//')" "$T/.buildaccel/distcc" "K DISTCC_DIR fallback when state dir is not writable"
    chmod 0755 "$R/state/distcc"
    cp "$R/ccache.conf" "$T/ccache.conf.keep"
    rm "$R/ccache.conf"
    reset_build
    src k10 10
    run_cc -c k10.c -o k10.o
    eq "$(last_stat)" "nocache cache-unusable" "K no ccache.conf"
    eq "$(tail -n 1 "$FCENV2" | cut -d' ' -f1)" "umask=0002" "K compiler umask (distcc path, no ccache)"
    cp "$T/ccache.conf.keep" "$R/ccache.conf"
    touch "$R/enabled"

    echo "== H: unwritable / missing cache dir -> cache-unusable (failure path)"
    cp "$R/ccache.conf" "$T/ccache.conf.good"
    mkdir -p "$T/ro"
    chmod 0555 "$T/ro"
    sed "s|^cache_dir = .*|cache_dir = $T/ro|" "$T/ccache.conf.good" >"$R/ccache.conf"
    rm "$R/enabled"
    reset_build
    src h 8
    before=$(ncompiles)
    run_cc -c h.c -o h.o
    eq "$(last_stat)" "nocache cache-unusable" "H stats line unwritable"
    eq "$(head -n 1 "$W/h.o")" "FAKEOBJ" "H object produced without cache"
    eq "$(( $(ncompiles) - before ))" "1" "H compiled once"
    ls -A "$T/ro" | grep -q . && fail "H probe file left behind"
    for f in "$T"/.buildaccel/inv/*/ccache-stats.log; do
      [ ! -e "$f" ] || fail "H ccache ran"
    done
    touch "$R/enabled"
    reset_build
    run_cc -c h.c -o h.o
    eq "$(last_stat)" "remote-nocache cache-unusable" "H stats line unwritable with server"
    sed "s|^cache_dir = .*|cache_dir = $T/missing|" "$T/ccache.conf.good" >"$R/ccache.conf"
    reset_build
    run_cc -c h.c -o h.o
    eq "$(last_stat)" "remote-nocache cache-unusable" "H stats line missing dir"
    chmod 0755 "$T/ro"
    cp "$T/ccache.conf.good" "$R/ccache.conf"

    echo "== I: --summary over prepared logs"
    # Per-invocation records, with ccache's internal cpp log kept separate.
    S=$T/sum
    mkdir -p "$S/.buildaccel/inv/i1" "$S/.buildaccel/inv/i2" "$S/.buildaccel/inv/i3"
    printf 'cache no-server exact\n' >"$S/.buildaccel/inv/i1/meta"
    printf 'remote ok exact\n' >"$S/.buildaccel/inv/i2/meta"
    printf 'remote-nocache cache-unusable exact\n' >"$S/.buildaccel/inv/i3/meta"
    printf '101\n' >"$S/.buildaccel/inv/i2/distcc-pids"
    printf '102\n' >"$S/.buildaccel/inv/i3/distcc-pids"
    # i1: cache hit, no compile
    printf '# a.c\ndirect_cache_hit\nlocal_storage_hit\nlocal_storage_read_hit\n' >"$S/.buildaccel/inv/i1/ccache-stats.log"
    printf 'distcc[90] exec on localhost: /x/gcc -E a.c\ndistcc[90] compile a.c on localhost completed ok\n' >"$S/.buildaccel/inv/i1/distcc-cpp.log"
    # i2: cache miss, compiled on qa-a
    printf '# b.c\ncache_miss\ndirect_cache_miss\nlocal_storage_miss\npreprocessed_cache_miss\n' >"$S/.buildaccel/inv/i2/ccache-stats.log"
    {
      echo "distcc[101] (dcc_trace_version) distcc ${pkgs.distcc.version} aarch64-unknown-linux-gnu; built Jan  1 1980 00:00:00"
      echo "distcc[101] exec on @qa-a/4,lzo: /x/gcc -c b.c -o b.o"
      echo "distcc[101] 153 bytes from b.c compiled on qa-a in 0.0100s, rate 15kB/s"
      echo "distcc[101] compile b.c on @qa-a/4,lzo completed ok"
      echo "distcc[101] elapsed compilation time 0.010000s"
    } >"$S/.buildaccel/inv/i2/distcc.log"
    # i3: remote fails, then local; copied log phrases in the input name
    # cannot match an anchored record or replace the last outcome suffix.
    {
      echo "distcc[102] (dcc_trace_version) distcc ${pkgs.distcc.version} aarch64-unknown-linux-gnu; built Jan  1 1980 00:00:00"
      echo "distcc[102] exec on @qa-b/3,lzo: /x/gcc -c c.c -o c.o"
      echo "distcc[102] (dcc_r_token_int) ERROR: read failed while waiting for token \"DONE\""
      echo "distcc[102] Warning: failed to distribute c.c to @qa-b/3,lzo, running locally instead"
      echo "distcc[102] exec on localhost: /x/gcc -c c.c -o c.o"
      echo "distcc[102] compile c on @qa-a/4,lzo completed ok on localhost completed ok"
      echo "distcc[102] elapsed compilation time 0.010000s"
    } >"$S/.buildaccel/inv/i3/distcc.log"
    printf 'cache no-server i1\nremote ok i2\nremote-nocache cache-unusable i3\n' >"$S/.buildaccel/stats"
    eq "$(TMPDIR=$S "$L" --summary)" "invocations=3 ccache-hits=1 ccache-misses=1 remote-ok=1 remote-failed=1 local=1 unaccounted=0 hosts=qa-a:1 skipped=cache-unusable:1,no-server:1" "I summary"
    mkdir -p "$T/empty"
    eq "$(TMPDIR=$T/empty "$L" --summary 2>&1)" "invocations=0 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=" "I summary without logs"

    echo "== J: malformed host data -> nothing usable, probe 0, silent"
    start_listener "$R/sock/Bad_Name" "EXEC:$CU/true"
    fresh Bad_Name
    printf '\n   \ngarbage\nqa-a\nqa-a 4\nqa-a x aarch64-linux\nqa-a 0 aarch64-linux\nqa-a 1.5 aarch64-linux\nqa-a 04 aarch64-linux\nqa-a 9223372036854775808 aarch64-linux\nqa-a +3 aarch64-linux\nqa-a -1 aarch64-linux\nqa-a 4 aarch64-linux extra\nBad_Name 4 aarch64-linux\n../x 4 aarch64-linux\naaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 4 aarch64-linux\n' >"$R/servers"
    fresh qa-a
    eq "$(probe)" "0" "J probe with malformed servers file"
    reset_build
    run_cc -c b.c -o b.o
    eq "$(last_stat)" "cache no-server" "J stats line"
    printf 'qa-b 3 aarch64-linux' >"$R/servers"
    fresh qa-b
    eq "$(probe)" "3" "J control: last line without newline is read"
    for h in "" "garbage" "ok notanumber" "ok" "ok 99999999999999999999" "ok -5" "OK $NOW" "down $NOW x" "ok $((NOW + 3600))"; do
      printf '%s\n' "$h" >"$R/health/qa-b"
      eq "$(probe)" "0" "J probe health [$h]"
    done
    : >"$R/health/qa-b"
    eq "$(probe)" "0" "J probe empty health file"
    rm "$R/health/qa-b"
    eq "$(probe)" "0" "J probe missing health file"
    rm "$R/servers"
    eq "$(probe)" "0" "J probe without servers file"

    echo "== K: bridge validation (failure path)"
    start_listener "$R/sock/qa-echo" "EXEC:$CU/echo bridge-ok"
    for h in Bad_Name "../x" "" "-x" "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" qa-missing; do
      rc=0
      timeout 10 "$BR" "$h" distccd --inetd --enable-tcp-insecure </dev/null >"$T/bout" 2>"$T/berr" || rc=$?
      [ "$rc" != 0 ] || fail "bridge accepted [$h]"
      [ "$rc" != 124 ] || fail "bridge hung on [$h]"
      [ ! -s "$T/bout" ] || fail "bridge wrote stdout for [$h]"
      [ ! -s "$T/berr" ] || fail "bridge wrote stderr for [$h]"
      echo "ok: bridge refused [$h] rc=$rc"
    done
    rc=0
    bout=$(timeout 10 "$BR" qa-echo distccd --inetd --enable-tcp-insecure </dev/null) || rc=$?
    eq "$rc:$bout" "0:bridge-ok" "K bridge connects a valid host"

    echo "== L: --health-check"
    hc() {
      local rc=0 o
      o=$(cd "$W" && "$L" --health-check "$@" 2>"$T/herr") || rc=$?
      [ ! -s "$T/herr" ] || fail "--health-check wrote stderr"
      printf '%s|%s' "$rc" "$o"
    }
    o=$(hc qa-d "$FC" "$T/fc")
    echo "observed: $o"
    [[ $o =~ ^0\|ok\ [0-9]+$ ]] || fail "L health ok: [$o]"
    o=$(hc qa-a "$FC" "$T/fc")
    echo "observed: $o"
    [[ $o =~ ^1\|down\ [0-9]+\ .+$ ]] || fail "L health down (server closes): [$o]"
    o=$(hc qa-missing "$FC" "$T/fc")
    echo "observed: $o"
    [[ $o =~ ^1\|down\ [0-9]+\ .+$ ]] || fail "L health down (no socket): [$o]"
    o=$(hc Bad_Name "$FC" "$T/fc")
    echo "observed: $o"
    [[ $o =~ ^1\|down\ [0-9]+\ invalid-arguments$ ]] || fail "L health invalid name: [$o]"

    echo "== M: real compiles whose file names / arguments look like flags or log records"
    # m_src <name>: source file with an old mtime (ccache direct mode)
    # (the log phrases contain "@qa-d/2,lzo", so the name has a directory part)
    m_src() {
      mkdir -p "$(dirname "$W/$1")"
      printf 'int m%s;\n' "$RANDOM" >"$W/$1"
      touch -d "@$((NOW - 100))" "$W/$1"
    }
    m_sum() { "$L" --summary; }
    M_NAMES=(
      "source -E note.c"
      "a -c b -o c.c"
      "distcc[1] compile a.c on @qa-d/2,lzo completed ok.c"
      $'nl\ndistcc[1] exec on localhost: gcc -c x.c\ndirect_cache_hit\n# z.c\ncache_miss\ndistcc[1] compile z.c on @qa-d/2,lzo completed ok\ny.c'
    )
    # local only (no enabled): miss + local, then a hit
    rm -f "$R/enabled"
    for n in "''${M_NAMES[@]}"; do
      reset_build
      m_src "$n"
      run_cc -c "$n" -o m.o
      eq "$(head -n 1 "$W/m.o")" "FAKEOBJ" "M object for [$n]"
      if [[ $n == *$'\n'* ]]; then
        eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=no-server:1" "M inexact local miss [$n]"
      else
        eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=no-server:1" "M local miss [$n]"
      fi
      run_cc -c "$n" -o m.o
      if [[ $n == *$'\n'* ]]; then
        eq "$(m_sum)" "invocations=2 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=2 hosts= skipped=no-server:2" "M inexact local hit [$n]"
      else
        eq "$(m_sum)" "invocations=2 ccache-hits=1 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=no-server:2" "M local hit [$n]"
      fi
    done
    echo "-- arguments (not file names) carrying the same text"
    reset_build
    m_src m1.c
    run_cc -c m1.c -o m1.o "-DNOTE= -E -c -o x" "-DLOG=distcc[1] compile m1.c on @qa-d/2,lzo completed ok" $'-DNL=1\ndistcc[1] exec on @qa-d/2,lzo: x\ndirect_cache_hit'
    eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=no-server:1" "M arguments with flag/log text"
    echo "-- remote success (distccd behind the bridge)"
    touch "$R/enabled"
    printf 'qa-d 2 aarch64-linux\n' >"$R/servers"
    fresh qa-d
    for n in "''${M_NAMES[@]}"; do
      reset_build
      m_src "$n"
      run_cc -c "$n" -o m.o
      eq "$(head -n 1 "$W/m.o")" "FAKEOBJ" "M remote object for [$n]"
      if [[ $n == *$'\n'* ]]; then
        eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "M inexact remote ok [$n]"
      else
        eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=1 remote-failed=0 local=0 unaccounted=0 hosts=qa-d:1 skipped=" "M remote ok [$n]"
      fi
    done
    echo "-- remote failure (server closes) then local fallback"
    printf 'qa-a 4 aarch64-linux\n' >"$R/servers"
    fresh qa-a
    for n in "''${M_NAMES[@]}"; do
      reset_build
      m_src "$n"
      run_cc -c "$n" -o m.o
      if [[ $n == *$'\n'* ]]; then
        eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "M inexact remote failed [$n]"
      else
        eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=0 remote-failed=1 local=1 unaccounted=0 hosts= skipped=" "M remote failed [$n]"
      fi
    done
    echo "-- no cache: distcc run directly by the launcher"
    cp "$R/ccache.conf" "$T/ccache.conf.keep2"
    rm "$R/ccache.conf"
    rm -f "$R/enabled"
    for n in "''${M_NAMES[@]}"; do
      reset_build
      m_src "$n"
      run_cc -c "$n" -o m.o
      if [[ $n == *$'\n'* ]]; then
        eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=cache-unusable:1" "M inexact nocache local [$n]"
      else
        eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=cache-unusable:1" "M nocache local [$n]"
      fi
    done
    cp "$T/ccache.conf.keep2" "$R/ccache.conf"

    echo "== N: exact cache and execution outcomes"
    rm -f "$R/enabled"
    reset_build
    m_src n.c
    run_cc -c n.c -o n.o -save-temps
    eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=deny:-save-temps:1" "N uncacheable save-temps"
    reset_build
    run_cc -c -E n.c -o n.i
    eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=no-server:1" "N explicit preprocessing"
    reset_build
    m_src $'a\ncache_miss'
    run_cc -x c -c $'a\ncache_miss' -o a -save-temps
    eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=deny:-save-temps:1" "N newline uncacheable header"
    reset_build
    printf '%s\n' '-c n.c -o n.o' >"$W/args"
    (cd "$W" && "$L" "$FC" @args) >"$T/out" 2>"$T/err"
    eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=deny:@args:1" "N response file"

    # Source-faithful records exercise outcomes hard to induce with the fake
    # compiler: stderr-copy retry, truncation, process exit before execution.
    P=$T/prepared
    PD=$P/.buildaccel/inv/p
    prepared() {
      rm -rf "$P"
      mkdir -p "$PD"
      printf 'remote ok p\n' >"$P/.buildaccel/stats"
      printf 'remote ok exact\n' >"$PD/meta"
      printf '# a.c\nunsupported_compiler_option\n' >"$PD/ccache-stats.log"
      printf '1\n' >"$PD/distcc-pids"
      : >"$PD/distcc.log"
    }
    finish_prepared() {
      local pid
      while IFS= read -r pid; do
        if ! grep -Fq "distcc[$pid] (dcc_trace_version)" "$PD/distcc.log"; then
          printf 'distcc[%s] (dcc_trace_version) distcc ${pkgs.distcc.version} aarch64-unknown-linux-gnu; built Jan  1 1980 00:00:00\n' "$pid" >"$PD/header"
          cat "$PD/distcc.log" >>"$PD/header"
          mv "$PD/header" "$PD/distcc.log"
        fi
        printf 'distcc[%s] elapsed compilation time 0.000001s\n' "$pid" >>"$PD/distcc.log"
      done <"$PD/distcc-pids"
    }
    prepared
    {
      echo 'distcc[1] exec on @qa-a/4,lzo: /x/gcc -c a.c -o a.o'
      echo 'distcc[1] compile a.c on @qa-a/4,lzo completed ok'
      echo 'distcc[1] (dcc_build_somewhere) Warning: Could not show server-side errors'
      echo 'distcc[1] Warning: failed to distribute a.c to @qa-a/4,lzo, running locally instead'
      echo 'distcc[1] exec on localhost: /x/gcc -c a.c -o a.o'
      echo 'distcc[1] compile a.c on localhost completed ok'
    } >"$PD/distcc.log"
    finish_prepared
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=1 remote-failed=0 local=1 unaccounted=0 hosts=qa-a:1 skipped=" "N remote success then local retry"
    prepared
    printf 'distcc[1] exec on @qa-a/4,lzo: /x/gcc -c a.c\n' >"$PD/distcc.log"
    # 18-byte prefix + 4070-byte input = exactly 4088 bytes without LF.
    printf 'distcc[1] compile %4070s\n' x >>"$PD/distcc.log"
    finish_prepared
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "N truncated outcome"
    prepared
    printf 'distcc[1] exec on @qa-a/4,lzo: /x/gcc -c a.c\n' >"$PD/distcc.log"
    finish_prepared
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "N unresolved remote attempt"
    prepared
    printf 'distcc[1] exec on @qa-a/4,lzo: /x/gcc -c a.c\ndistcc[1] exec on localhost: /x/gcc -c a.c\n' >"$PD/distcc.log"
    printf 'distcc[1] compile a.c on localhost completed ok\n' >>"$PD/distcc.log"
    finish_prepared
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=1 local=1 unaccounted=0 hosts= skipped=" "N remote attempt followed by local"
    prepared
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "N empty stream cannot prove compiler never ran"
    finish_prepared
    printf 'cache no-server gone\ncache no-server -\n' >>"$P/.buildaccel/stats"
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=3 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=no-server:2" "N missing invocation directories"
    for bad in missing-header extra-header invalid-id both-hit-miss malformed-distcc orphan-ok; do
      prepared
      printf 'distcc[1] exec on localhost: /x/gcc -c a.c\n' >"$PD/distcc.log"
      case $bad in
        missing-header) printf 'cache_miss\n' >"$PD/ccache-stats.log" ;;
        extra-header) printf '# a.c\ncache_miss\n# b.c\n' >"$PD/ccache-stats.log" ;;
        invalid-id) printf '# a.c\ncache-miss\n' >"$PD/ccache-stats.log" ;;
        both-hit-miss) printf '# a.c\ncache_miss\ndirect_cache_hit\n' >"$PD/ccache-stats.log" ;;
        malformed-distcc) printf 'unprefixed\n' >>"$PD/distcc.log" ;;
        orphan-ok) printf 'distcc[1] compile a.c on @qa-a/4,lzo completed ok\n' >>"$PD/distcc.log" ;;
      esac
      finish_prepared
      eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "N invalid records $bad"
    done

    echo "== O: required records and independent invocation identities"
    for kind in lost-distcc lost-cache header-only missing-meta stats-unwritable hit-no-distcc read-only-area; do
      reset_build
      m_src "o-$kind.c"
      if [[ $kind == stats-unwritable ]]; then
        : >"$T/.buildaccel/stats"
        chmod 0444 "$T/.buildaccel/stats"
      elif [[ $kind == read-only-area ]]; then
        chmod 0555 "$T/.buildaccel"
      fi
      run_cc -c "o-$kind.c" -o "o-$kind.o"
      if [[ $kind == read-only-area ]]; then
        eq "$(head -n 1 "$W/o-$kind.o")" "FAKEOBJ" "O empty read-only record area produces object"
        eq "$(m_sum)" "invocations=0 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=" "O unavailable record channels"
        chmod 0755 "$T/.buildaccel"
        continue
      fi
      OD=("$T"/.buildaccel/inv/*)
      eq "$(cat "''${OD[0]}/meta")" "cache no-server exact" "O $kind positive meta"
      case $kind in
        lost-distcc) rm "''${OD[0]}/distcc.log" ;;
        lost-cache) rm "''${OD[0]}/ccache-stats.log" ;;
        header-only) printf '# a.c\n' >"''${OD[0]}/ccache-stats.log" ;;
        missing-meta) rm "''${OD[0]}/meta" ;;
        stats-unwritable)
          eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=no-server:1" "O stats unwritable preserves invocation"
          chmod 0644 "$T/.buildaccel/stats"
          continue ;;
        hit-no-distcc)
          run_cc -c "o-$kind.c" -o "o-$kind.o"
          OID=$(tail -n 1 "$T/.buildaccel/stats" | cut -d' ' -f3)
          [ ! -e "$T/.buildaccel/inv/$OID/distcc.log" ] || fail "O cache hit ran own distcc"
          eq "$(m_sum)" "invocations=2 ccache-hits=1 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=no-server:2" "O real hit without own distcc log"
          continue ;;
      esac
      eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=no-server:1" "O required record $kind"
    done
    for severity in "" "EMERGENCY! " "ALERT! " "CRITICAL! " "ERROR: " "Warning: "; do
      prepared
      printf 'distcc[1] exec on @qa-a/4,lzo: /x/gcc -c a.c\n' >"$PD/distcc.log"
      prefix="distcc[1] ''${severity}compile "
      printf '%s%*s\n' "$prefix" "$((4088 - ''${#prefix}))" x >>"$PD/distcc.log"
      printf 'distcc[1] exec on localhost: /x/gcc -c a.c\n' >>"$PD/distcc.log"
      finish_prepared
      eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "O truncated critique severity [$severity]"
    done
    prepared
    rm "$PD/meta"
    finish_prepared
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "O missing meta"

    echo "== P: adversarial damaged records and impossible event sequences"
    for bad in nul-meta nul-cache nul-distcc partial-meta partial-cache partial-distcc \
      duplicate-meta duplicate-id duplicate-local duplicate-attempt duplicate-ok \
      wrong-host ok-before-attempt local-before-remote hit-with-execution \
      duplicate-stats symlink-distcc; do
      prepared
      A='distcc[1] exec on @qa-a/1,lzo: /x/gcc -c a.c'
      OK='distcc[1] compile a.c on @qa-a/1,lzo completed ok'
      LOCAL='distcc[1] exec on localhost: /x/gcc -c a.c'
      case $bad in
        nul-meta) printf 'remote o\0k exact\n' >"$PD/meta" ;;
        nul-cache) printf '# a.c\ncache_\0miss\n' >"$PD/ccache-stats.log" ;;
        nul-distcc) printf 'distcc[1] exec on local\0host: /x/gcc\n' >"$PD/distcc.log" ;;
        partial-meta) printf 'remote ok exact' >"$PD/meta" ;;
        partial-cache) printf '# a.c\ncache_miss' >"$PD/ccache-stats.log" ;;
        partial-distcc) printf '%s' "$LOCAL" >"$PD/distcc.log" ;;
        duplicate-meta) printf 'remote ok exact\nremote ok exact\n' >"$PD/meta" ;;
        duplicate-id) printf '# a.c\ncache_miss\ncache_miss\n' >"$PD/ccache-stats.log" ;;
        duplicate-local) printf '%s\n' "$LOCAL" "$LOCAL" >"$PD/distcc.log" ;;
        duplicate-attempt) printf '%s\n' "$A" "$A" "$OK" >"$PD/distcc.log" ;;
        duplicate-ok) printf '%s\n' "$A" "$OK" "$OK" >"$PD/distcc.log" ;;
        wrong-host) printf '%s\n' "$A" "''${OK/qa-a/qa-b}" >"$PD/distcc.log" ;;
        ok-before-attempt) printf '%s\n' "$OK" "$A" >"$PD/distcc.log" ;;
        local-before-remote) printf '%s\n' "$LOCAL" "$A" "$OK" >"$PD/distcc.log" ;;
        hit-with-execution)
          printf '# a.c\ndirect_cache_hit\n' >"$PD/ccache-stats.log"
          printf '%s\n' "$LOCAL" >"$PD/distcc.log" ;;
        duplicate-stats) printf 'remote ok p\n' >>"$P/.buildaccel/stats" ;;
        symlink-distcc)
          mv "$PD/distcc.log" "$PD/saved.log"
          ln -s "$PD/saved.log" "$PD/distcc.log" ;;
      esac
      if [[ $bad != partial-distcc && $bad != symlink-distcc ]]; then finish_prepared; fi
      eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "P rejects $bad"
    done
    prepared
    printf '%s\n' "$A" "''${A/qa-a/qa-b}" "''${OK/qa-a/qa-b}" >"$PD/distcc.log"
    finish_prepared
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=1 remote-failed=1 local=0 unaccounted=0 hosts=qa-b:1 skipped=" "P retry on another remote host"
    prepared
    printf '%s\n' "$A" 'distcc[2] exec on @qa-a/1,lzo: /x/gcc -c a.c' "$OK" 'distcc[2] exec on localhost: /x/gcc -c a.c' >"$PD/distcc.log"
    printf 'distcc[2] compile a.c on localhost completed ok\n' >>"$PD/distcc.log"
    printf '2\n' >>"$PD/distcc-pids"
    finish_prepared
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=1 remote-failed=1 local=1 unaccounted=0 hosts=qa-a:1 skipped=" "P interleaved pids remain independent"
    for missing in p -; do
      prepared
      rm -rf "$PD"
      printf 'remote ok %s\n' "$missing" >"$P/.buildaccel/stats"
      eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=" "P stats identity [$missing] without a directory"
    done
    for area in log directory; do
      prepared
      chmod 0444 "$PD/distcc.log"
      if [[ $area == directory ]]; then chmod 0555 "$PD"; fi
      # Exercise the real prefix entrypoint, as ccache's fallback exec does.
      (cd "$W" &&
        BUILDACCEL_INV="$PD" DISTCC_DIR="$R/state/distcc" \
          DISTCC_HOSTS="localhost/2" DISTCC_VERBOSE=1 \
          "$BASH" -c 'export BUILDACCEL_PREFIX_PARENT=$$; exec "$@"' \
          prefix "$L" "$FC" -c n.c -o append-failure.o) >"$T/out" 2>"$T/err"
      [ ! -s "$T/out" ] && [ ! -s "$T/err" ] || fail "P append-create failure leaked output"
      eq "$(head -n 1 "$W/append-failure.o")" "FAKEOBJ" "P append failure still compiles [$area]"
      eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "P append-create failure [$area]"
      chmod 0755 "$PD"
    done

    echo "== Q: identity sources that are writable but not fully readable"
    for kind in unlistable-inv symlink-stats writeonly-stats; do
      reset_build
      m_src "q-$kind.c"
      if [[ $kind == unlistable-inv ]]; then
        mkdir "$T/.buildaccel/inv"
        chmod 0300 "$T/.buildaccel/inv"
      else
        printf 'blocked\n' >"$T/.buildaccel/inv"
        if [[ $kind == symlink-stats ]]; then
          : >"$T/secondary-stats"
          ln -s "$T/secondary-stats" "$T/.buildaccel/stats"
        else
          : >"$T/.buildaccel/stats"
          chmod 0200 "$T/.buildaccel/stats"
        fi
      fi
      run_cc -c "q-$kind.c" -o "q-$kind.o"
      eq "$(head -n 1 "$W/q-$kind.o")" "FAKEOBJ" "Q object [$kind]"
      case $kind in
        unlistable-inv)
          eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=unknown hosts= skipped=no-server:1" "Q stats id resolves without listing inv"
          chmod 0700 "$T/.buildaccel/inv" ;;
        symlink-stats)
          eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=no-server:1" "Q readable stats symlink" ;;
        writeonly-stats)
          eq "$(m_sum)" "invocations=0 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=" "Q unreadable identity source"
          chmod 0600 "$T/.buildaccel/stats" ;;
      esac
    done

    prepared
    rm -rf "$P/.buildaccel/inv" "$P/.buildaccel/stats"
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=0 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=" "Q emptied existing record area"

    echo "== R: positive client receipts and complete execution streams"
    for bad in missing-pids empty-pids bad-pid duplicate-pid partial-pid \
      empty-stream header-only missing-end duplicate-end event-after-end unrecorded-event; do
      prepared
      printf 'distcc[1] exec on localhost: /x/gcc -c a.c\ndistcc[1] compile a.c on localhost completed ok\n' >"$PD/distcc.log"
      finish_prepared
      case $bad in
        missing-pids) rm "$PD/distcc-pids" ;;
        empty-pids) : >"$PD/distcc-pids" ;;
        bad-pid) printf '01\n' >"$PD/distcc-pids" ;;
        duplicate-pid) printf '1\n1\n' >"$PD/distcc-pids" ;;
        partial-pid) printf '1' >"$PD/distcc-pids" ;;
        empty-stream) : >"$PD/distcc.log" ;;
        header-only) printf 'distcc[1] (dcc_trace_version) distcc 3.4\n' >"$PD/distcc.log" ;;
        missing-end) printf 'distcc[1] exec on localhost: /x/gcc -c a.c\n' >"$PD/distcc.log" ;;
        duplicate-end) finish_prepared ;;
        event-after-end)
          printf 'distcc[1] elapsed compilation time 0.000001s\ndistcc[1] exec on localhost: /x/gcc -c a.c\n' >"$PD/distcc.log" ;;
        unrecorded-event)
          printf 'distcc[2] exec on localhost: /x/gcc -c a.c\ndistcc[2] elapsed compilation time 0.000001s\n' >>"$PD/distcc.log" ;;
      esac
      eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "R rejects $bad"
    done
    prepared
    printf '92359\n' >"$PD/distcc-pids"
    printf '%s\n' \
      'distcc[92359] (dcc_trace_version) distcc ${pkgs.distcc.version} aarch64-apple-darwin25.6.0; built Jan  1 1980 00:00:00' \
      'distcc[92359] exec on @qa-real/1,lzo: /x/clang -c warn.c' \
      'distcc[92368] (dcc_increment_safeguard) setting safeguard: _DISTCC_SAFEGUARD=1' \
      'distcc[92359] compile warn.c on @qa-real/1,lzo completed ok' \
      'distcc[92359] (dcc_build_somewhere) Warning: Could not show server-side errors' \
      'distcc[92359] exec on localhost: /x/clang -c warn.c' \
      'distcc[92374] (dcc_increment_safeguard) setting safeguard: _DISTCC_SAFEGUARD=1' \
      'distcc[92359] ERROR: compile warn.c on localhost: Segmentation fault: 11' \
      'distcc[92359] elapsed compilation time 9.478447s' >"$PD/distcc.log"
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=1 remote-failed=0 local=1 unaccounted=0 hosts=qa-real:1 skipped=" "R client end with forked child diagnostics"
    prepared
    printf '# a.c\nlocal_storage_hit\nlocal_storage_read_hit\n' >"$PD/ccache-stats.log"
    rm "$PD/distcc.log" "$PD/distcc-pids"
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "R preprocessed hit truncated before terminal id"
    prepared
    chmod 0444 "$PD/distcc-pids"
    (cd "$W" &&
      BUILDACCEL_INV="$PD" DISTCC_DIR="$R/state/distcc" \
        DISTCC_HOSTS="localhost/2" DISTCC_VERBOSE=1 \
        "$BASH" -c 'export BUILDACCEL_PREFIX_PARENT=$$; exec "$@"' \
        prefix "$L" "$FC" -c n.c -o pid-failure.o) >"$T/out" 2>"$T/err"
    [ ! -s "$T/out" ] && [ ! -s "$T/err" ] || fail "R pid append failure leaked output"
    eq "$(head -n 1 "$W/pid-failure.o")" "FAKEOBJ" "R pid append failure still compiles"
    eq "$(cat "$PD/inexact")" "pid-record-failed" "R pid append failure marker"
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "R pid append failure excludes outcomes"

    prepared
    printf 'distcc[1] exec on localhost: /x/gcc -c a.c\ndistcc[1] compile a.c on localhost completed ok\n' >"$PD/distcc.log"
    finish_prepared
    cp -R "$PD" "$P/.buildaccel/inv/copy0001"
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=2 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=2 hosts= skipped=" "R duplicate invocation receipts exclude both identities"

    echo "== S: recorded client stream grammar"
    for bad in head-loss local-orphan remote-orphan remote-failure-orphan \
      duplicate-critique local-without-critique remote-without-critique no-execution; do
      prepared
      printf '%s\n' "$LOCAL" 'distcc[1] compile a.c on localhost completed ok' >"$PD/distcc.log"
      case $bad in
        local-orphan) printf 'distcc[1] compile a.c on localhost completed ok\n' >"$PD/distcc.log" ;;
        remote-orphan) printf '%s\n' "$OK" >"$PD/distcc.log" ;;
        remote-failure-orphan) printf 'distcc[1] ERROR: compile a.c on @qa-a/1,lzo failed\n' >"$PD/distcc.log" ;;
        duplicate-critique) printf 'distcc[1] compile a.c on localhost completed ok\n' >>"$PD/distcc.log" ;;
        local-without-critique) printf '%s\n' "$LOCAL" >"$PD/distcc.log" ;;
        remote-without-critique) printf '%s\n' "$A" >"$PD/distcc.log" ;;
        no-execution) : >"$PD/distcc.log" ;;
      esac
      finish_prepared
      if [[ $bad == head-loss ]]; then
        tail -n +2 "$PD/distcc.log" >"$PD/suffix"
        mv "$PD/suffix" "$PD/distcc.log"
      fi
      eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "S rejects $bad"
    done
    for severity in "" "EMERGENCY! " "ALERT! " "CRITICAL! " "ERROR: " "Warning: "; do
      prepared
      printf '%s\n' "$A" "distcc[1] ''${severity}compile a.c on @qa-a/1,lzo failed" "$LOCAL" \
        "distcc[1] ''${severity}compile a.c on localhost failed with exit code 2" >"$PD/distcc.log"
      finish_prepared
      eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=1 local=1 unaccounted=0 hosts= skipped=" "S matched failure critiques [$severity]"
    done
    # compile.c 770-772: --scan-includes returns through the timed wrapper
    # without an execution or critique. include_server_if.c 183-188 returns
    # EXIT_DISTCC_FAILED (100) for a host without cpp. Keep this path excluded.
    prepared
    scan_rc=0
    DISTCC_DIR="$R/state/distcc" DISTCC_HOSTS="@qa-a/1,lzo" \
      DISTCC_LOG="$PD/distcc.log" DISTCC_VERBOSE=1 DISTCC_NO_REWRITE_CROSS=1 \
      "$DISTCC" --scan-includes ${pkgs.llvmPackages.clang}/bin/clang -c "$W/n.c" -o "$W/scan.o" >"$T/scan-out" 2>"$T/scan-err" || scan_rc=$?
    eq "$scan_rc" 100 "S scan-includes returns before execution"
    sed -n '1s/^distcc\[\([0-9]*\)\].*/\1/p' "$PD/distcc.log" >"$PD/distcc-pids"
    grep -q 'elapsed compilation time' "$PD/distcc.log" || fail "S scan-includes has no end"
    if grep -Eq 'exec on |compile .* on .* (completed ok|failed)' "$PD/distcc.log"; then fail "S scan-includes executed"; fi
    eq "$(TMPDIR=$P "$L" --summary)" "invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=" "S legitimate no-execution end is excluded"

    # Real writer boundary: observe L, truncate while Clang waits on FIFO,
    # then let the client append its genuine critique and end.
    L="$L" CC=${pkgs.llvmPackages.clang}/bin/clang ${pkgs.nodejs}/bin/node --input-type=module <<'JS'
    import {mkdtemp,mkdir,writeFile,readFile,truncate,stat,rm} from 'node:fs/promises';
    import {watch,readdirSync,readFileSync} from 'node:fs';
    import {spawn,spawnSync} from 'node:child_process';
    import assert from 'node:assert/strict';
    const L=process.env.L, CC=process.env.CC;
    const t=await mkdtemp(process.env.TMPDIR+'/live-truncation.');
    let child,watcher,timer;
    try {
      for(const p of ['r/state/distcc','tmp']) await mkdir(t+'/'+p,{recursive:true});
      assert.equal(spawnSync('mkfifo',[t+'/hold.c']).status,0);
      const env={...process.env,BUILDACCEL_ROOT:t+'/r',TMPDIR:t+'/tmp',BUILDACCEL_LOCAL_CORES:'1'};
      const started=new Promise((resolve,reject)=>{
        timer=setTimeout(()=>reject(new Error('execution marker timeout')),10000);
        watcher=watch(t+'/tmp',{recursive:true},()=>{
          try {
            for(const id of readdirSync(t+'/tmp/.buildaccel/inv')) {
              const path=t+'/tmp/.buildaccel/inv/'+id+'/distcc.log';
              if(readFileSync(path,'utf8').includes('exec on localhost:')) {
                watcher.close();clearTimeout(timer);resolve(path);return;
              }
            }
          } catch(e) {if(e.code!=='ENOENT')reject(e);}
        });
      });
      child=spawn(L,[CC,'-c','hold.c','-o','a.o'],{cwd:t,env,stdio:['ignore','pipe','pipe']});
      let out="",err="";child.stdout.on('data',x=>out+=x);child.stderr.on('data',x=>err+=x);
      const closed=new Promise(resolve=>child.once('close',(code,signal)=>resolve({code,signal})));
      const path=await started;
      await truncate(path,0);
      await writeFile(t+'/hold.c','int a;\n');
      assert.equal((await closed).code,0);assert.equal(out+err,"");
      assert.ok((await stat(t+'/a.o')).size>0);
      const raw=await readFile(path,'utf8');
      assert.match(raw,/compile hold.c on localhost completed ok/);
      assert.match(raw,/elapsed compilation time/);
      assert.doesNotMatch(raw,/exec on localhost:/);
      const s=spawnSync(L,['--summary'],{env,encoding:'utf8',timeout:5000});
      assert.equal(s.status,0);
      assert.equal(s.stdout.trim(),'invocations=1 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=1 hosts= skipped=cache-unusable:1');
      console.log('ok: S live truncation after L = '+s.stdout.trim());
    } finally {
      clearTimeout(timer);watcher?.close();
      if(child?.exitCode===null && child?.signalCode===null)child.kill('SIGKILL');
      await rm(t,{recursive:true,force:true});
    }
    JS

    echo "== T: pre-existing blocking paths and missing history"
    rm -f "$R/enabled"
    for kind in stats-fifo stats-symlink primary-lock fallback-lock lock-symlink \
      state-fifo lock-dir-fifo distcc-dir-fifo no-inv; do
      reset_build
      m_src "t-$kind.c"
      case $kind in
        stats-fifo) mkfifo "$T/.buildaccel/stats" ;;
        stats-symlink)
          mkfifo "$T/stats-target"
          ln -s "$T/stats-target" "$T/.buildaccel/stats" ;;
        fallback-lock)
          chmod 0555 "$R/state/distcc"
          mkdir -p "$T/.buildaccel/distcc/lock"
          mkfifo "$T/.buildaccel/distcc/lock/cpu_localhost_0" ;;
        lock-symlink)
          mkdir "$T/lock-target"
          mkfifo "$T/lock-target/cpu_localhost_0"
          ln -s "$T/lock-target" "$R/state/distcc/lock" ;;
        state-fifo)
          mkdir "$R/state/distcc/state"
          mkfifo "$R/state/distcc/state/binstate_1" ;;
        lock-dir-fifo) mkfifo "$R/state/distcc/lock" ;;
        distcc-dir-fifo)
          rmdir "$R/state/distcc"
          mkfifo "$R/state/distcc" ;;
        primary-lock | no-inv)
          mkdir "$R/state/distcc/lock"
          mkfifo "$R/state/distcc/lock/cpu_localhost_0"
          if [[ $kind == no-inv ]]; then
            printf 'blocked\n' >"$T/.buildaccel/inv"
          fi ;;
      esac
      rc=0
      (cd "$W" && "$CU/timeout" 10 "$L" "$FC" -c "t-$kind.c" -o "t-$kind.o") >"$T/out" 2>"$T/err" || rc=$?
      eq "$rc" 0 "T bounded compile [$kind]"
      [ ! -s "$T/out" ] && [ ! -s "$T/err" ] || fail "T streams [$kind]"
      eq "$(head -n 1 "$W/t-$kind.o")" "FAKEOBJ" "T object [$kind]"
      if [[ $kind == fallback-lock ]]; then chmod 0755 "$R/state/distcc"; fi
      case $kind in
        stats-*)
          eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=unknown hosts= skipped=no-server:1" "T unavailable stats [$kind]" ;;
        no-inv)
          eq "$(m_sum)" "invocations=0 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=" "T unsafe state without invocation skips distcc" ;;
        *)
          TD=("$T"/.buildaccel/inv/*)
          eq "$(tail -n 1 "$FCENV2" | sed 's/^umask=[0-9]* cfg=.* ddir=//; s/ dlog=.*//')" "''${TD[0]}/distcc" "T fresh private state [$kind]"
          eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=no-server:1" "T private-state outcome [$kind]" ;;
      esac
    done
    reset_build
    m_src t-history.c
    run_cc -c t-history.c -o t-history.o
    eq "$(m_sum)" "invocations=1 ccache-hits=0 ccache-misses=1 remote-ok=0 remote-failed=0 local=1 unaccounted=0 hosts= skipped=no-server:1" "T history before removal"
    rm -rf "$T/.buildaccel"
    eq "$(m_sum)" "invocations=0 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=" "T removed record area"
    mkdir "$T/.buildaccel"
    eq "$(m_sum)" "invocations=0 ccache-hits=0 ccache-misses=0 remote-ok=0 remote-failed=0 local=0 unaccounted=unknown hosts= skipped=" "T empty record area"

    echo "== launcher usage error goes to stderr only"
    rc=0
    "$L" >"$T/uout" 2>/dev/null || rc=$?
    [ "$rc" = 2 ] && [ ! -s "$T/uout" ] || fail "usage error"

    cleanup
    trap - EXIT
    LISTENERS=()
    echo "all launcher checks passed"
    touch "$out"
  ''
