#!@bash@/bin/bash
# shellcheck shell=bash
#
# buildaccel-launcher - client side of build acceleration (template/buildaccel).
#
# Generic code: every host-specific value is read at runtime from
#   R="${BUILDACCEL_ROOT:-/run/buildaccel/v1}"
#     $R/enabled          toggle file
#     $R/servers          lines "<name> <slots> <system>"
#     $R/ccache.conf      ccache configuration (names cache_dir)
#     $R/sock/<name>      unix socket forwarding to the server
#     $R/health/<name>    "ok <epoch>" | "down <epoch> <reason>"
#     $R/state/           writable state (distcc locks and backoff)
# Per-build files live in B="$TMPDIR/.buildaccel": stats (one "<branch> <reason>"
# line per compile call, including its id) and inv/<id>/ per call: meta,
# ccache-stats.log, distcc-pids (client pids), distcc.log (own command), distcc-cpp.log (ccache's
# preprocessor), optional inexact (prefix arguments became unloggable).
#
# Modes:
#   buildaccel-launcher --probe
#       print the sum of slots of usable servers for $BUILDACCEL_SYSTEM; 0 on any problem
#   buildaccel-launcher --summary
#       print "invocations=.. ccache-hits=.. ccache-misses=.. remote-ok=.. remote-failed=..
#       local=.. unaccounted=.. hosts=<name:count,...> skipped=<reason:count,...>"
#   buildaccel-launcher --health-check <name> <gcc> <bintools-bin>
#       end-to-end distcc compile on <name>; prints "ok <epoch>" (exit 0) or
#       "down <epoch> <first error line>" (exit 1)
#   buildaccel-launcher <real-compiler> <args...>
#       compile through ccache and distcc; prints nothing itself
#   (internal) ccache's CCACHE_PREFIX: when BUILDACCEL_PREFIX_PARENT names this
#       process or its parent, select the own-command log and exec distcc
set -u

CU=@coreutils@/bin
CCACHE=@ccache@/bin/ccache
DISTCC=@distcc@/bin/distcc
BRIDGE=@bridge@
SELF="${BRIDGE%/*}/buildaccel-launcher"

R="${BUILDACCEL_ROOT:-/run/buildaccel/v1}"
B="${TMPDIR:-/tmp}/.buildaccel"
NAME_RE='^[a-z][a-z0-9-]{0,31}$'
FRESH_SECONDS=120
NOW=0

set_now() {
  NOW=$("$CU/date" +%s 2>/dev/null) || NOW=0
  [[ $NOW =~ ^[0-9]{1,12}$ ]] || NOW=0
}

# health_fresh <name>: the health file says "ok <epoch>" with 0 <= now-epoch <= 120.
health_fresh() {
  local f="$R/health/$1" st="" ep="" rest="" age
  [[ -f $f && -r $f ]] || return 1
  IFS=$' \t' read -r st ep rest <"$f" || true
  [[ $st == ok && $ep =~ ^[0-9]{1,12}$ ]] || return 1
  ((NOW > 0)) || return 1
  age=$((NOW - 10#$ep))
  ((age >= 0 && age <= FRESH_SECONDS))
}

# Slot counts are canonical positive decimal integers that fit in a signed
# 64-bit integer (the range of Nix integers): 1 <= v <= 9223372036854775807.
SLOT_MAX=9223372036854775807
# valid_slots <s>: digits only, no sign, no leading zero, within SLOT_MAX.
# The bound is checked on the digit string, never by overflowing arithmetic.
valid_slots() {
  local s=$1 hi lo
  [[ $s =~ ^[1-9][0-9]*$ ]] || return 1
  ((${#s} < 19)) && return 0
  ((${#s} == 19)) || return 1
  hi=${s:0:10}
  lo=${s:10}
  ((10#$hi < 9223372036 || (10#$hi == 9223372036 && 10#$lo <= 854775807)))
}

# distcc 3.4 keeps per-host slots in an int (src/hosts.h 48) parsed with
# atoi (src/hosts.c 220-227), so DISTCC_HOSTS gets min(slots, INT_MAX);
# distcc itself never locks more than 10000 slots per host (src/where.c 175).
DISTCC_SLOT_MAX=2147483647

# collect_servers: fill U_NAMES/U_SLOTS/U_TOTAL with usable servers for the
# build's system. Usable = valid line, socket exists, fresh "ok" health.
# A connect to the local socket is never attempted: the forwarder accepts
# before it dials the server, so it would prove nothing.
U_NAMES=()
U_SLOTS=()
U_TOTAL=0
# A sum above SLOT_MAX is a problem: no server is usable (probe prints 0,
# compile mode runs locally), so --probe and compile mode always agree.
collect_servers() {
  local overflow=0
  U_NAMES=()
  U_SLOTS=()
  U_TOTAL=0
  [[ -f $R/enabled && -f $R/servers && -r $R/servers ]] || return 0
  local want="${BUILDACCEL_SYSTEM:-}" name slots sys extra
  local -A seen=()
  if [[ -z $want ]]; then
    want="$("$CU/uname" -m 2>/dev/null)-linux"
  fi
  set_now
  while name="" slots="" sys="" extra="" && IFS=$' \t' read -r name slots sys extra || [[ -n $name ]]; do
    [[ $name =~ $NAME_RE ]] || continue
    # No policy cap here: todo 3's hook bounds the aggregate it applies.
    valid_slots "$slots" || continue
    [[ $sys == "$want" && -z $extra ]] || continue
    [[ -z ${seen[$name]:-} ]] || continue
    [[ -S $R/sock/$name ]] || continue
    health_fresh "$name" || continue
    seen[$name]=1
    if ((U_TOTAL > SLOT_MAX - slots)); then
      overflow=1
      break
    fi
    U_NAMES+=("$name")
    U_SLOTS+=("$slots")
    U_TOTAL=$((U_TOTAL + slots))
  done <"$R/servers"
  if ((overflow)); then
    U_NAMES=()
    U_SLOTS=()
    U_TOTAL=0
  fi
}

# cache_usable: ccache's temporary directory is writable, and the cache_dir
# named in ccache.conf permits creating and removing a probe file.
cache_usable() {
  local conf="$R/ccache.conf" line dir="" p
  [[ -d $CCACHE_TEMPDIR && -w $CCACHE_TEMPDIR ]] || return 1
  [[ -f $conf && -r $conf ]] || return 1
  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line =~ ^[[:space:]]*cache_dir[[:space:]]*=[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
      dir=${BASH_REMATCH[1]}
    fi
  done <"$conf"
  [[ -n $dir && -d $dir ]] || return 1
  p=$("$CU/mktemp" "$dir/.buildaccel-probe.XXXXXX" 2>/dev/null) || return 1
  "$CU/rm" -f "$p" 2>/dev/null
}

unset_inherited() {
  local v
  local -a names=()
  mapfile -t names < <(compgen -e)
  for v in "${names[@]}"; do
    case $v in
    CCACHE_* | DISTCC_* | BUILDACCEL_INV | BUILDACCEL_PREFIX_PARENT) unset "$v" ;;
    esac
  done
}

mode_probe() {
  exec 2>/dev/null
  collect_servers
  if [[ $U_TOTAL =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$U_TOTAL"
  else
    printf '0\n'
  fi
}

# join_counts <assoc-name>: "k1:v1,k2:v2" sorted by key.
join_counts() {
  local -n m=$1
  local k out=""
  local -a keys=()
  ((${#m[@]})) || return 0
  mapfile -t keys < <(printf '%s\n' "${!m[@]}" | LC_ALL=C "$CU/sort")
  for k in "${keys[@]}"; do
    out+="${out:+,}$k:${m[$k]}"
  done
  printf '%s' "$out"
}

# Bash read discards embedded NULs. Producer records never contain them, so
# reject such corruption before a discarded byte can change a field or event.
text_record() {
  local _content
  [[ -f $1 && -r $1 ]] || return 1
  ! IFS= read -r -d '' _content <"$1"
}

valid_route() {
  case $1:$2 in
  cache:no-server | cache:deny:* | remote:ok | nocache:cache-unusable | \
    nocache:deny:* | remote-nocache:cache-unusable) return 0 ;;
  esac
  return 1
}

mode_summary() {
  exec 2>/dev/null
  export LC_ALL=C
  local hits=0 misses=0 rok=0 rfail=0 loc=0 inv=0 unaccounted=0
  local d line branch reason id state name pid previous exact hit miss ids first
  local local_runs remote_ok remote_failed lines meta_ok
  local inv_channel=0 stats_channel=0 identity_complete=1 partial
  local -A identities=()
  local -A hosts=() skipped=() stat_branch=() stat_reason=() stat_seen=() stat_bad=()
  local -A pending=() finished=() seen_attempt=() oks=() clients=() ends=()
  local -A started=() execution=() critiques=()
  local -A pid_owner=() shared_pid=()
  local re_route='(cache|remote|nocache|remote-nocache) (ok|no-server|cache-unusable|deny:[^[:space:],]+)'
  local re_stats="^$re_route ([A-Za-z0-9][A-Za-z0-9_-]*|-)$"
  local re_meta="^$re_route (exact|inexact:[a-z][a-z-]*)$"
  # Check identity channels without creating anything. If neither could
  # record a call, even the number of missing invocations is unknown.
  if [[ -d $B/inv && -w $B/inv ]] ||
    [[ ! -e $B/inv && ! -L $B/inv && -d $B && -w $B ]] ||
    [[ ! -e $B && ! -L $B && -d ${TMPDIR:-/tmp} && -w ${TMPDIR:-/tmp} ]]; then
    inv_channel=1
  fi
  if [[ -f $B/stats && -w $B/stats ]] ||
    [[ ! -e $B/stats && ! -L $B/stats && -d $B && -w $B ]] ||
    [[ ! -e $B && ! -L $B && -d ${TMPDIR:-/tmp} && -w ${TMPDIR:-/tmp} ]]; then
    stats_channel=1
  fi
  # A hidden identity source must remain visible as unknown completeness.
  # A regular-file inv obstruction is instead a complete empty source:
  # no invocation directory could have been created underneath it.
  [[ ! -d $B || -x $B ]] || identity_complete=0
  [[ ! -L $B/inv ]] || identity_complete=0
  if [[ -d $B/inv ]]; then
    if [[ -r $B/inv && -x $B/inv ]]; then
      for d in "$B"/inv/* "$B"/inv/.[!.]* "$B"/inv/..?*; do
        [[ -e $d || -L $d ]] || continue
        identities[${d##*/}]=1
      done
    else
      identity_complete=0
    fi
  elif [[ -e $B/inv || -L $B/inv ]] && [[ ! -f $B/inv ]]; then
    identity_complete=0
  fi
  # Appends follow a stats symlink, so the reader follows it too. Keep the
  # union of listed names and stats ids, even if the parent is unlistable.
  if [[ -f $B/stats && -r $B/stats ]]; then
    text_record "$B/stats" || identity_complete=0
    while line="" && {
      IFS= read -r line
      partial=$?
      ((partial == 0)) || [[ -n $line ]]
    }; do
      ((partial == 0)) || identity_complete=0
      [[ $line != *$'\001'* ]] || identity_complete=0
      if [[ $line != *$'\001'* && $line =~ $re_stats ]]; then
        branch=${BASH_REMATCH[1]} reason=${BASH_REMATCH[2]} id=${BASH_REMATCH[3]}
        if valid_route "$branch" "$reason" && [[ $id != - ]]; then
          identities[$id]=1
          [[ -z ${stat_seen[$id]:-} ]] || stat_bad[$id]=1
          stat_seen[$id]=1 stat_branch[$id]=$branch stat_reason[$id]=$reason
          continue
        fi
        # Without an inv directory, a complete-line stats tail loss is
        # indistinguishable from fewer calls. Keep known counts, disclose
        # unknown completeness instead of asserting a numeric missing count.
        identity_complete=0
        if valid_route "$branch" "$reason" && [[ $reason != ok ]]; then
          skipped[$reason]=$((${skipped[$reason]:-0} + 1))
        fi
      fi
      inv=$((inv + 1)) unaccounted=$((unaccounted + 1))
    # Bash discards NULs; replace them with an invalid field byte while
    # retaining other readable lines. text_record already marks unknown.
    done < <("$CU/tr" '\000' '\001' <"$B/stats")
  elif [[ -e $B/stats || -L $B/stats ]]; then
    identity_complete=0
  fi
  # A copied invocation directory (or pid reuse) makes matching receipts
  # ambiguous across identities. Exclude every participant, not just the
  # second one encountered by the reader.
  for id in "${!identities[@]}"; do
    d="$B/inv/$id"
    if [[ ! -L $d/distcc-pids ]] && text_record "$d/distcc-pids"; then
      while IFS= read -r pid; do
        [[ $pid =~ ^[1-9][0-9]*$ ]] || continue
        if [[ -n ${pid_owner[$pid]:-} && ${pid_owner[$pid]} != "$id" ]]; then
          shared_pid[$pid]=1
        else
          pid_owner[$pid]=$id
        fi
      done <"$d/distcc-pids"
    fi
  done
  # trace.c 247-271 prefixes records with distcc[pid]. trace.c 83-85 lists
  # exactly EMERGENCY!, ALERT!, CRITICAL!, ERROR: and Warning: (each plus a
  # space); rs_format_msg 264-270 inserts severity before the message.
  # exec.c 565-609 uses ERROR for failure critiques, no severity for success.
  # compile.c 393 -> exec.c 90-97 emits each own local exec; remote.c 218
  # emits each remote exec. hosts.c 577 preserves @name/slots,lzo verbatim.
  # compile.c 854 -> exec.c 606-609 emits OK; greedy .* selects the last
  # " on @" suffix, so an input name cannot substitute an earlier host.
  local re_prefix='^distcc\[([0-9]+)\] '
  local re_local='^exec on localhost: '
  local re_att='^exec on @([a-z][a-z0-9-]{0,31})/[1-9][0-9]*,lzo: '
  local re_compile='^(EMERGENCY! |ALERT! |CRITICAL! |ERROR: |Warning: )?compile '
  local re_ok='^compile .* on @([a-z][a-z0-9-]{0,31})/[1-9][0-9]*,lzo completed ok$'
  # distcc.c 242 calls help.c 42-47 before any client work. Real logs
  # have "built Jan  1 1980 00:00:00" (no colon after "built").
  local re_start='^\(dcc_trace_version\) distcc @distccversion@ [^[:space:];]+; built [A-Z][a-z]{2} [ 0-9][0-9] [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
  # exec.c 577-609: success, exit failure, and both signal formats.
  # Greedy input matching selects the last host/outcome suffix.
  local outcome='( completed ok| failed( with exit code [0-9]+)?|: .+| terminated by signal [0-9]+( \(core dumped\))?)$'
  local re_critique="^(EMERGENCY! |ALERT! |CRITICAL! |ERROR: |Warning: )?compile .* on (localhost|@([a-z][a-z0-9-]{0,31})/[1-9][0-9]*,lzo)$outcome"
  # compile.c 1011-1014: dcc_build_somewhere_timed logs this after returning.
  # Only launcher-recorded client pids need it; forked compiler/cpp children
  # can log diagnostics before exec without returning through this function.
  local re_end='^elapsed compilation time -?[0-9]+\.[0-9]{6}s$'
  for id in "${!identities[@]}"; do
    d="$B/inv/$id"
    if [[ -n ${stat_seen[$id]:-} ]] && [[ ! -d $d || -L $d ]]; then
      identity_complete=0
    fi
    inv=$((inv + 1))
    exact=1 hit=0 miss=0 local_runs=0 remote_ok=0 remote_failed=0 first=1 ids=0
    # If even a failure marker could not be appended, existing files cannot
    # establish that their producer was able to record this invocation.
    [[ -d $d && -w $d && -x $d && ! -L $d ]] || exact=0
    pending=() finished=() seen_attempt=() oks=() clients=() ends=()
    started=() execution=() critiques=()
    meta_ok=0 lines=0 branch="" reason="" state=""
    if [[ ! -L $d/meta ]] && text_record "$d/meta"; then
      while IFS= read -r line; do
        lines=$((lines + 1))
        if ((lines == 1)) && [[ $line =~ $re_meta ]]; then
          branch=${BASH_REMATCH[1]} reason=${BASH_REMATCH[2]} state=${BASH_REMATCH[3]}
          valid_route "$branch" "$reason" && meta_ok=1
        else
          meta_ok=0
        fi
      done <"$d/meta"
      [[ -z $line && $lines == 1 ]] || meta_ok=0
    fi
    if ((meta_ok == 0)); then
      reason=${stat_reason[$id]:-}
      exact=0
    else
      [[ $state == exact ]] || exact=0
      if [[ -n ${stat_seen[$id]:-} ]]; then
        [[ $branch == "${stat_branch[$id]}" && $reason == "${stat_reason[$id]}" ]] || exact=0
      fi
    fi
    [[ -z ${stat_bad[$id]:-} && ! -e $d/inexact && ! -L $d/inexact ]] || exact=0
    if [[ -n $reason && $reason != ok ]]; then
      skipped[$reason]=$((${skipped[$reason]:-0} + 1))
    fi
    # ccache 4.13.6 statslog.cpp 62-79 writes a raw '# input' header then
    # ids from ccache.cpp 2774-2790 / statistics.cpp 314-326. One complete
    # block with at least one id is required on cache/remote branches.
    case $branch in
    cache | remote)
      if [[ -L $d/ccache-stats.log ]] || ! text_record "$d/ccache-stats.log"; then
        exact=0
      else
        while IFS= read -r line; do
          if ((first)); then
            [[ $line == '# '* ]] || exact=0
            first=0
          else
            [[ $line =~ ^[a-z][a-z0-9_]*$ ]] || exact=0
            ids=$((ids + 1))
            case $line in
            direct_cache_hit | preprocessed_cache_hit) hit=$((hit + 1)) ;;
            cache_miss) miss=$((miss + 1)) ;;
            esac
          fi
        done <"$d/ccache-stats.log"
        [[ -z $line ]] || exact=0
        ((first == 0 && ids > 0 && hit + miss < 2)) || exact=0
      fi
      ;;
    nocache | remote-nocache)
      [[ ! -e $d/ccache-stats.log && ! -L $d/ccache-stats.log ]] || exact=0
      ;;
    *) exact=0 ;;
    esac
    if [[ -e $d/distcc-pids || -L $d/distcc-pids ]]; then
      if [[ -L $d/distcc-pids ]] || ! text_record "$d/distcc-pids"; then
        exact=0
      else
        while IFS= read -r pid; do
          if [[ $pid =~ ^[1-9][0-9]*$ && -z ${clients[$pid]:-} ]]; then
            clients[$pid]=1
            [[ -z ${shared_pid[$pid]:-} ]] || exact=0
          else
            exact=0
          fi
        done <"$d/distcc-pids"
        [[ -z $pid ]] || exact=0
      fi
    fi
    ((hit > 0 || ${#clients[@]} > 0)) || exact=0
    if [[ ! -L $d/distcc.log ]] && text_record "$d/distcc.log"; then
      while IFS= read -r line; do
        if [[ ! $line =~ $re_prefix ]]; then
          exact=0
          continue
        fi
        pid=${BASH_REMATCH[1]}
        state=${line#*] }
        if [[ -n ${clients[$pid]:-} && -z ${started[$pid]:-} ]]; then
          [[ $state =~ $re_start ]] || exact=0
          started[$pid]=1
        fi
        if [[ $state =~ $re_end && -n ${clients[$pid]:-} ]]; then
          ends[$pid]=$((${ends[$pid]:-0} + 1))
          [[ -z ${execution[$pid]:-} && ${critiques[$pid]:-0} != 0 ]] || exact=0
        fi
        if [[ $state =~ $re_critique ]]; then
          previous=L
          if [[ ${BASH_REMATCH[2]} != localhost ]]; then
            name=${BASH_REMATCH[3]}
            previous="A:$name"
            [[ ${pending[$pid]:-} == "$name" ]] || exact=0
          fi
          [[ -n ${clients[$pid]:-} && ${ends[$pid]:-0} == 0 &&
            ${execution[$pid]:-} == "$previous" ]] || exact=0
          unset 'execution[$pid]'
          critiques[$pid]=$((${critiques[$pid]:-0} + 1))
        fi
        if [[ $state =~ $re_local || $state =~ $re_att || $state =~ $re_ok ]]; then
          [[ -n ${clients[$pid]:-} && ${ends[$pid]:-0} == 0 ]] || exact=0
        fi
        # trace.c 322-331 caps a 4090-byte buffer at sizeof(buf)-2=4088
        # before LF. Check every compile message, including severity prefixes.
        if [[ $state =~ $re_compile ]] && ((${#line} >= 4088)); then
          exact=0
        fi
        if [[ $state =~ $re_local ]]; then
          [[ ${execution[$pid]:-} != L ]] || exact=0
          execution[$pid]=L
          [[ ${finished[$pid]:-} != local ]] || exact=0
          previous=${pending[$pid]:-}
          if [[ -n $previous ]]; then
            remote_failed=$((remote_failed + 1))
            unset 'pending[$pid]'
          fi
          local_runs=$((local_runs + 1))
          finished[$pid]=local
        elif [[ $state =~ $re_att ]]; then
          name=${BASH_REMATCH[1]}
          [[ ${execution[$pid]:-} != L ]] || exact=0
          execution[$pid]="A:$name"
          # A pid runs one own command. After OK it can only fall back to L;
          # after L it exits (compile.c 854-870,935-948). Duplicated events
          # cannot establish new executions; launcher host names are unique.
          [[ -z ${finished[$pid]:-} && -z ${seen_attempt[$pid:$name]:-} ]] || exact=0
          seen_attempt[$pid:$name]=1
          if [[ -n ${pending[$pid]:-} ]]; then
            remote_failed=$((remote_failed + 1))
          fi
          pending[$pid]=$name
        elif [[ $state =~ $re_ok ]]; then
          name=${BASH_REMATCH[1]}
          if [[ ${pending[$pid]:-} != "$name" ]]; then
            exact=0
          else
            unset 'pending[$pid]'
            remote_ok=$((remote_ok + 1))
            oks[$name]=$((${oks[$name]:-0} + 1))
            finished[$pid]=remote
          fi
        fi
      done <"$d/distcc.log"
      [[ -z $line ]] || exact=0
      # A->A proves failure at compile.c 829-845 (choose_host); A->L proves
      # failure at 908-948 (fallback). A pending at EOF proves neither: the
      # client may die after the server succeeded but before critique.
      ((${#pending[@]} == 0)) || exact=0
      ((hit == 0 || (local_runs == 0 && remote_ok == 0 && remote_failed == 0))) || exact=0
    elif ((hit == 0)) || [[ -e $d/distcc.log || -L $d/distcc.log ]]; then
      exact=0
    fi
    for pid in "${!clients[@]}"; do
      # compile.c 694-698 can fail setup, 770-772 scans includes without
      # execution; 398-402 can fail spawn/collection without a critique.
      # Their end alone cannot distinguish legitimate inactivity from loss.
      ((${ends[$pid]:-0} == 1)) || exact=0
    done
    if ((exact == 0)); then
      unaccounted=$((unaccounted + 1))
      continue
    fi
    hits=$((hits + hit)) misses=$((misses + miss)) loc=$((loc + local_runs))
    rok=$((rok + remote_ok)) rfail=$((rfail + remote_failed))
    for name in "${!oks[@]}"; do
      hosts[$name]=$((${hosts[$name]:-0} + oks[$name]))
    done
  done
  # Missing history cannot prove empty history, even when B is absent.
  # An opted-in build that ran no compile therefore also reports unknown.
  if ((inv == 0)); then
    identity_complete=0
  fi
  ((identity_complete && (inv_channel || stats_channel))) || unaccounted=unknown
  printf 'invocations=%s ccache-hits=%s ccache-misses=%s remote-ok=%s remote-failed=%s local=%s unaccounted=%s hosts=%s skipped=%s\n' \
    "$inv" "$hits" "$misses" "$rok" "$rfail" "$loc" "$unaccounted" "$(join_counts hosts)" "$(join_counts skipped)"
}

mode_health_check() {
  local name="${1:-}" gcc="${2:-}" bin="${3:-}" d rc msg="" line
  exec 2>/dev/null
  unset_inherited
  set_now
  if [[ ! $name =~ $NAME_RE || -z $gcc || -z $bin ]]; then
    printf 'down %s invalid-arguments\n' "$NOW"
    return 1
  fi
  if ! d=$("$CU/mktemp" -d "${TMPDIR:-/tmp}/buildaccel-health.XXXXXX"); then
    printf 'down %s mktemp-failed\n' "$NOW"
    return 1
  fi
  printf 'int buildaccel_health;\n' >"$d/h.c"
  # distcc creates only the last level below DISTCC_DIR (dcc_mkdir), not DISTCC_DIR itself.
  "$CU/mkdir" -p "$d/distcc"
  (
    cd "$d" &&
      DISTCC_HOSTS="@$name/1" \
        DISTCC_SSH="$BRIDGE" \
        DISTCC_FALLBACK=0 \
        DISTCC_SKIP_LOCAL_RETRY=1 \
        DISTCC_IO_TIMEOUT=20 \
        DISTCC_DIR="$d/distcc" \
        exec "$CU/timeout" 30 "$DISTCC" "$gcc" "-B$bin/" -c h.c -o h.o
  ) <"/dev/null" >"$d/out" 2>"$d/err"
  rc=$?
  set_now
  if ((rc == 0)) && [[ -s $d/h.o ]]; then
    "$CU/rm" -rf "$d"
    printf 'ok %s\n' "$NOW"
    return 0
  fi
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line//[$'\t\r']/ }
    line=${line#distcc\[*\] }
    if [[ -n ${line//[[:space:]]/} ]]; then
      msg=$line
      break
    fi
  done <"$d/err"
  if [[ -z $msg ]]; then
    if ((rc == 124)); then msg="timeout"; else msg="exit-$rc"; fi
  fi
  "$CU/rm" -rf "$d"
  printf 'down %s %s\n' "$NOW" "${msg:0:200}"
  return 1
}

mode_compile() {
  local real=$1 a deny="" C branch reason cache=1 i ds hosts_spec distcc_dir inv=""
  local exactness=exact loggable=1
  local unsafe_state=0 entries
  local record_id=-
  shift
  unset_inherited
  umask 0002

  # Local slots go to distcc's int --localslots (src/hosts.c 213-227): a
  # canonical positive value up to INT_MAX, else nproc (NIX_BUILD_CORES=0
  # means "all cores", and distcc rejects a zero multiplier, hosts.c 221).
  C="${BUILDACCEL_LOCAL_CORES:-}"
  if ! valid_slots "$C" || ((C > DISTCC_SLOT_MAX)); then
    C=$("$CU/nproc" 2>/dev/null) || C=1
    [[ $C =~ ^[1-9][0-9]{0,8}$ ]] || C=1
  fi

  [[ -d $B/ccache-tmp && -d $B/inv ]] || "$CU/mkdir" -p "$B/ccache-tmp" "$B/inv" 2>/dev/null
  # Separate logs keep ccache's internal preprocessing out of own-command counts.
  inv=$("$CU/mktemp" -d "$B/inv/XXXXXXXX" 2>/dev/null) || inv=""
  [[ -z $inv ]] || record_id=${inv##*/}
  for a in "$real" "$@"; do
    case $a in
    *$'\n'*) exactness=inexact:newline loggable=0 ;;
    @*) exactness=inexact:response-file ;;
    esac
  done
  export CCACHE_CONFIGPATH="$R/ccache.conf"
  export CCACHE_COMPILERCHECK="string:$real"
  export CCACHE_TEMPDIR="$B/ccache-tmp"
  cache_usable || cache=0

  for a in "$@"; do
    case $a in
    -march=native | -mcpu=native | -mtune=native | -fplugin* | -fpass-plugin* | \
      -fprofile-use* | -fprofile-instr-use* | -fprofile-sample-use* | -fsanitize=* | \
      -fsanitize-ignorelist* | -include-pch | -fmodules* | @* | -save-temps* | \
      -Xclang | -specs=* | -wrapper | --config*)
      deny=$a
      break
      ;;
    esac
  done

  if [[ -z $deny ]]; then
    collect_servers
  else
    U_NAMES=()
    U_SLOTS=()
    U_TOTAL=0
  fi

  distcc_dir="$R/state/distcc"
  if [[ ( ! -e $distcc_dir && ! -L $distcc_dir ) ||
    ( -d $distcc_dir && ! -w $distcc_dir ) ]]; then
    distcc_dir="$B/distcc"
    "$CU/mkdir" -p "$distcc_dir" 2>/dev/null
  fi
  # lock.c 253 opens locks/backoff with O_WRONLY|O_CREAT; state.c 142
  # opens process state with O_CREAT|O_WRONLY|O_TRUNC. Neither rejects FIFOs.
  [[ -d $distcc_dir ]] || unsafe_state=1
  if ((unsafe_state == 0)); then
    for a in "$distcc_dir/lock" "$distcc_dir/state"; do
      [[ -e $a || -L $a ]] || continue
      if [[ ! -d $a ]] ||
        ! entries=$("@findutils@/bin/find" -H "$a" -mindepth 1 ! -type f -print -quit 2>/dev/null) ||
        [[ -n $entries ]]; then
        unsafe_state=1
        break
      fi
    done
  fi
  if ((unsafe_state)); then
    # Only sabotaged state loses the shared local-slot bound. Fresh private
    # state cannot contain pre-arranged blocking paths; without it skip distcc.
    if [[ -z $inv ]] || ! "$CU/mkdir" "$inv/distcc" 2>/dev/null; then
      exec "$real" "$@"
    fi
    distcc_dir="$inv/distcc"
  fi
  export DISTCC_DIR="$distcc_dir"
  export DISTCC_VERBOSE=1
  # ccache runs its own preprocessor through distcc with the cpp log; only
  # mode_prefix switches to the own-command log immediately before exec.
  export CCACHE_PREFIX="$SELF"
  export CCACHE_PREFIX_CPP="$DISTCC"
  if [[ -n $inv ]]; then
    for a in "$PWD" "${TMPDIR:-/tmp}" "$R" "$distcc_dir"; do
      [[ $a != *$'\n'* ]] || exactness=inexact:newline
    done
    # Carries only the record directory across ccache to mode_prefix.
    export BUILDACCEL_INV="$inv"
    export CCACHE_STATSLOG="$inv/ccache-stats.log"
    if { : >>"$inv/distcc-cpp.log"; } 2>/dev/null; then
      export DISTCC_LOG="$inv/distcc-cpp.log"
    else
      export DISTCC_LOG=/dev/null
    fi
  else
    export CCACHE_STATSLOG=/dev/null
    export DISTCC_LOG=/dev/null
  fi

  if [[ -z $deny && ${#U_NAMES[@]} -gt 0 ]]; then
    hosts_spec="--localslots=$C --localslots_cpp=$C"
    for i in "${!U_NAMES[@]}"; do
      ds=${U_SLOTS[$i]}
      ((ds <= DISTCC_SLOT_MAX)) || ds=$DISTCC_SLOT_MAX
      hosts_spec+=" @${U_NAMES[$i]}/$ds,lzo"
    done
    export DISTCC_HOSTS="$hosts_spec"
    export DISTCC_SSH="$BRIDGE"
    export DISTCC_NO_REWRITE_CROSS=1
    export DISTCC_FALLBACK=1
    export DISTCC_BACKOFF_PERIOD=60
    export DISTCC_IO_TIMEOUT=120
    if ((cache)); then
      branch="remote" reason="ok"
    else
      branch="remote-nocache" reason="cache-unusable"
    fi
  else
    export DISTCC_HOSTS="--localslots=$C --localslots_cpp=$C localhost/$C"
    if ((cache)); then branch="cache"; else branch="nocache"; fi
    if [[ -n $deny ]]; then
      reason="deny:${deny//[[:space:],]/_}"
    elif ((cache)); then
      reason="no-server"
    else
      reason="cache-unusable"
    fi
  fi

  # Positive identity record: one printf, before either dependency can run.
  [[ -z $inv ]] || printf '%s %s %s\n' "$branch" "$reason" "$exactness" 2>/dev/null >"$inv/meta"
  if [[ -f $B/stats || ( ! -e $B/stats && ! -L $B/stats ) ]]; then
    printf '%s %s %s\n' "$branch" "$reason" "$record_id" 2>/dev/null >>"$B/stats"
  fi
  if ((cache)); then
    # ccache (this pid after exec) starts CCACHE_PREFIX as a child, or execs it
    # in place on its fall-back path (src/ccache/ccache.cpp 2905-2915).
    export BUILDACCEL_PREFIX_PARENT="$$"
    exec "$CCACHE" "$real" "$@"
  fi
  export DISTCC_LOG=/dev/null
  if [[ -n $inv ]]; then
    if ((loggable)); then
      if { : >>"$inv/distcc.log"; } 2>/dev/null; then
        export DISTCC_LOG="$inv/distcc.log"
      else
        printf 'log-create-failed\n' 2>/dev/null >>"$inv/inexact"
      fi
    elif { : >>"$inv/distcc-unloggable.log"; } 2>/dev/null; then
      export DISTCC_LOG="$inv/distcc-unloggable.log"
    fi
    # This pid survives exec; child diagnostic pids are not client streams.
    if ! { printf '%s\n' "$$" >>"$inv/distcc-pids"; } 2>/dev/null; then
      printf 'pid-record-failed\n' 2>/dev/null >>"$inv/inexact"
      export DISTCC_LOG=/dev/null
    fi
  fi
  exec "$DISTCC" "$real" "$@"
}

# mode_prefix <real> <args...>: ccache's compile prefix (see mode_compile).
mode_prefix() {
  local inv="${BUILDACCEL_INV:-}" a loggable=1
  unset BUILDACCEL_PREFIX_PARENT
  export DISTCC_LOG=/dev/null
  if [[ -n $inv ]]; then
    for a in "$@"; do
      [[ $a != *$'\n'* ]] || loggable=0
    done
    if ((loggable)); then
      if { : >>"$inv/distcc.log"; } 2>/dev/null; then
        export DISTCC_LOG="$inv/distcc.log"
      else
        printf 'log-create-failed\n' 2>/dev/null >>"$inv/inexact"
      fi
    else
      printf 'newline\n' 2>/dev/null >>"$inv/inexact"
      if { : >>"$inv/distcc-unloggable.log"; } 2>/dev/null; then
        export DISTCC_LOG="$inv/distcc-unloggable.log"
      fi
    fi
    if ! { printf '%s\n' "$$" >>"$inv/distcc-pids"; } 2>/dev/null; then
      printf 'pid-record-failed\n' 2>/dev/null >>"$inv/inexact"
      export DISTCC_LOG=/dev/null
    fi
  fi
  exec "$DISTCC" "$@"
}

# Prefix mode only for the ccache started by mode_compile: its child
# (PPID) or ccache itself after its fall-back exec ($$). A compile started any
# other way never has either pid in BUILDACCEL_PREFIX_PARENT, since that
# process is still alive as its ancestor.
if [[ -n ${BUILDACCEL_PREFIX_PARENT:-} ]] &&
  [[ $BUILDACCEL_PREFIX_PARENT == "$$" || $BUILDACCEL_PREFIX_PARENT == "$PPID" ]]; then
  mode_prefix "$@"
fi

case "${1:-}" in
--probe) mode_probe ;;
--summary) mode_summary ;;
--health-check)
  shift
  mode_health_check "$@"
  ;;
"" | -*)
  printf 'usage: buildaccel-launcher --probe | --summary | --health-check <name> <gcc> <bintools-bin> | <compiler> <args...>\n' >&2
  exit 2
  ;;
*) mode_compile "$@" ;;
esac
