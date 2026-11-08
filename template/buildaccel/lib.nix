{ lib }:
{
  forPkgs =
    pkgs:
    let
      launcher = import ./launcher.nix { inherit pkgs; };
      shim = import ./shim.nix { inherit pkgs launcher; };
      stdenvFor =
        stdenv:
        if stdenv.cc.cc.isBuildAccelShim or false then
          stdenv
        else
          pkgs.overrideCC stdenv (
            stdenv.cc.override {
              cc = shim {
                cc = stdenv.cc.cc;
                bintools = stdenv.cc.bintools;
                isClang = stdenv.cc.isClang;
              };
            }
          );
      boostHook = pkgs.makeSetupHook {
        name = "buildaccel-hook";
        substitutions = { inherit launcher; };
      } ./boost-hook.sh;
    in
    {
      accelerate =
        drv:
        assert lib.assertMsg (
          drv ? override && drv ? overrideAttrs && drv ? stdenv
        ) "buildaccel: accelerate needs a callPackage-built derivation";
        if (drv.BUILDACCEL_OPTIN or (drv.env.BUILDACCEL_OPTIN or null)) == "buildaccel-optin-v1" then
          drv
        else
          (drv.override { stdenv = stdenvFor drv.stdenv; }).overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ boostHook ];
            env =
              (old.env or { })
              // {
                BUILDACCEL_OPTIN = "buildaccel-optin-v1";
              }
              // lib.optionalAttrs (
                !(old ? NIX_OUTPATH_USED_AS_RANDOM_SEED) && !((old.env or { }) ? NIX_OUTPATH_USED_AS_RANDOM_SEED)
              ) { NIX_OUTPATH_USED_AS_RANDOM_SEED = "buildaccel"; };
          });
    };
}
