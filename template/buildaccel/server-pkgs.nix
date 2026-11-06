{ pkgs }:
{
  distccPatched = pkgs.distcc.overrideAttrs (o: {
    patches = (o.patches or [ ]) ++ [ ./distcc-resolver.patch ];
  });
  resolver = pkgs.writeShellApplication {
    name = "buildaccel-resolver";
    # nix-store and logger come from the Linux service's path. Dry-run skips
    # both, so Darwin checks need only the portable filesystem tools.
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./resolver.sh;
  };
}
