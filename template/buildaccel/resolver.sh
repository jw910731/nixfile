# shellcheck shell=bash
# Compilers and arguments arrive from the LAN; never interpret them as shell.
compiler=${1-}
dryrun=${BUILDACCEL_RESOLVER_DRYRUN:-0}
export LC_ALL=C

# Untrusted values go into one-line log messages: replace control characters
# (newline, CR, escapes) so they can never split or forge a log line.
sanitize() {
  printf '%s' "${1//[[:cntrl:]]/?}"
}

refuse() {
  if [[ $dryrun != 1 ]]; then
    logger -t buildaccel-resolver "$(sanitize "refused reason=$1 compiler=$compiler")" >/dev/null 2>&1 || true
  fi
  exit 111
}

compiler_re='^/nix/store/[0-9a-z]{32}-[^/]+/bin/[^/]+$'
basename_re='^(.*-)?(gcc|g\+\+|cc|c\+\+|clang|clang\+\+|clang-[0-9]+)$'
[[ $compiler =~ $compiler_re && ! $compiler =~ (^|/)\.\.(/|$) ]] || refuse compiler
basename=${compiler##*/}
[[ $basename =~ $basename_re ]] || refuse compiler

# Reject any argument that can make the compiler load or run code from a
# path we do not control. Rejecting whole prefixes covers every spelling a
# driver accepts: the exact flag, the joined `flag=value` and `flagvalue`
# forms, and the separate form (the flag token is matched regardless of its
# following value argument). gcc's driver remaps a leading `--` to `-f`
# (gcc/opts-common.cc option_map), so `--plugin=`, `--pass-plugin=`,
# `--profile-use` and friends alias the `-f` options and must be rejected
# too. The `-specs`, `-specs=...` and `--specs` spellings (the long form
# maps to `-specs`) are gcc driver aliases (gcc/common.opt) and are rejected.
# clang forwards `-Xclang=<arg>` and `-mllvm[=]<arg>` to cc1/LLVM (clang
# Driver/Options.td), which can load pass/frontend plugins (e.g.
# `-Xclang -load`, `-mllvm -load=`).
#
# -Xassembler/-Wa, are deliberately NOT rejected: during a `-c` compile of
# preprocessed input these forward only to GNU as, which has no plugin or
# code-loading option (it only tunes encoding of the already-parsed TU) and
# reads `@file` as option text, not code; they cannot change which code the
# toolchain runs, and real kernel builds pass them, so refusing would force
# needless local fallback. -fplugin-arg-* is covered by -fplugin* and is
# inert without a (refused) -fplugin.
for arg in "${@:2}"; do
  case "$arg" in
    -fplugin*|--plugin*|-fpass-plugin*|--pass-plugin*|\
    -load|-load=*|-Xclang*|-mllvm*|-wrapper|--wrapper*|\
    -specs*|--specs*|--config*|@*|\
    -fprofile-use*|-fprofile-instr-use*|-fprofile-sample-use*|\
    --profile-use*|--profile-instr-use*|--profile-sample-use*|\
    -fsanitize-ignorelist*|-fsanitize-blacklist*|\
    --sanitize-ignorelist*|--sanitize-blacklist*)
      refuse "flag:${arg%%=*}"
      ;;
    -B*)
      [[ $arg == -B/nix/store/* && ! ${arg#-B} =~ (^|/)\.\.(/|$) ]] || refuse flag:-B
      ;;
  esac
done

root=${compiler%/bin/*}
roots=("$root")
store_re='/nix/store/[0-9a-z]{32}-[A-Za-z0-9+._?=-]+'
for arg in "${@:2}"; do
  rest=$arg
  while [[ $rest =~ $store_re ]]; do
    root=${BASH_REMATCH[0]}
    found=0
    for known in "${roots[@]}"; do
      [[ $root != "$known" ]] || found=1
    done
    if [[ $found == 0 ]]; then
      roots+=("$root")
    fi
    rest=${rest#*"$root"}
  done
done
for index in "${!roots[@]}"; do
  root=${roots[$index]}
  if [[ $dryrun == 1 ]]; then
    printf 'realise %q\n' "$root"
  elif ! nix-store --realise "$root" --option max-jobs 0 --option builders '' >/dev/null 2>&1; then
    [[ $index != 0 ]] || refuse compiler-unavailable
  fi
done

cwd=$PWD
marker_re='^# [0-9]+ "(/build(/[A-Za-z0-9._+-]+)+)//"$'
for arg in "${@:2}"; do
  case "$arg" in
    *.i|*.ii|*.mi|*.mii)
      if [[ -f $arg && -r $arg ]]; then
        line_number=0
        while IFS= read -r line || [[ -n $line ]]; do
          line_number=$((line_number + 1))
          if [[ $line =~ $marker_re ]]; then
            candidate=${BASH_REMATCH[1]}
            if [[ ! $candidate =~ (^|/)\.\.(/|$) ]]; then
              cwd=$candidate
              break
            fi
          fi
          [[ $line_number -lt 5 ]] || break
        done < "$arg"
      fi
      ;;
  esac
done

if [[ $basename == *clang* ]]; then
  set -- "$@" -Wno-unused-command-line-argument
fi
if [[ $dryrun == 1 ]]; then
  # Report the intended cwd without mkdir or cd: /build is outside the Darwin
  # sandbox, and relative input paths must still resolve against the real cwd.
  printf 'cwd %q\n' "$cwd"
  printf 'argv'
  printf ' %q' "$@"
  printf '\n'
else
  if ! mkdir -p -- "$cwd" >/dev/null 2>&1 || ! cd -- "$cwd" 2>/dev/null; then
    refuse cwd
  fi
  logger -t buildaccel-resolver "$(sanitize "ok compiler=$compiler cwd=$cwd")" >/dev/null 2>&1 || true
  exec env -i PATH= HOME=/var/empty TMPDIR="$TMPDIR" "$@"
fi
