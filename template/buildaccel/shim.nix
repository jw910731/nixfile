# Compiler shim: a drop-in replacement for an unwrapped compiler (`cc` of a
# cc-wrapper), modelled on nixpkgs' `ccache.links`. Compiler entry points run
# shim.sh; every other entry symlinks into the real compiler.
{ pkgs, launcher }:
{
  cc,
  bintools,
  isClang,
}:
let
  inherit (pkgs) lib;
in
pkgs.runCommand "buildaccel-shim-${cc.name}"
  {
    passthru = {
      isBuildAccelShim = true;
      inherit isClang;
      isGNU = cc.isGNU or false;
      # Stops cc-wrapper from hiding arguments in clang response files.
      isCcache = true;
      inherit (cc) version;
      lib = lib.getLib cc;
      # Keeps cc-wrapper's ccName (wrapper pname and mainProgram) that of the
      # real compiler instead of "buildaccel-shim-...".
      pname = lib.getName cc;
    }
    // builtins.intersectAttrs {
      hardeningUnsupportedFlagsByTargetPlatform = null;
      hardeningUnsupportedFlags = null;
    } cc;
    meta = {
      inherit (cc.meta) mainProgram;
    };
  }
  ''
    # dotglob: hidden entries are kept too (bash never yields . or ..);
    # whether an entry is wrapped depends only on the basename regex.
    shopt -s dotglob nullglob
    mkdir -p "$out/bin"
    re='^(.*-)?(gcc|g\+\+|cc|c\+\+|clang|clang\+\+|clang-[0-9]+)$'
    for p in ${cc}/bin/*; do
      name="''${p##*/}"
      if [[ $name =~ $re ]]; then
        substitute ${./shim.sh} "$out/bin/$name" \
          --subst-var-by bash ${pkgs.bash}/bin/bash \
          --subst-var-by real "${cc}/bin/$name" \
          --subst-var-by mode ${if isClang then "clang" else "gcc"} \
          --subst-var-by bintools ${bintools} \
          --subst-var-by launcher ${launcher}
        chmod +x "$out/bin/$name"
      else
        ln -s "$p" "$out/bin/$name"
      fi
    done
    for p in ${cc}/*; do
      if [[ ''${p##*/} != bin ]]; then
        ln -s "$p" "$out/"
      fi
    done
  ''
