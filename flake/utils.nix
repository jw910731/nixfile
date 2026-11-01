# Per-system plumbing shared by the formatter and devShells outputs.
{ inputs, lib }:
let
  systems = {
    linux = [ "x86_64-linux" "aarch64-linux" ];
    darwin = [ "aarch64-darwin" "x86_64-darwin" ];
  };
  allSystems = systems.linux ++ systems.darwin;
  # Platform recognition lives here only: the table above decides the channel.
  nixpkgsFor =
    system:
    if lib.elem system systems.darwin then
      inputs.nixpkgs-darwin
    else if lib.elem system systems.linux then
      inputs.nixpkgs
    else
      throw "utils: unsupported system ${system}";
  # Same construction as the old pkgs' (plain import, no flake legacyPackages overlays); one instance per system.
  pkgsBySystem = lib.genAttrs allSystems (system: import (nixpkgsFor system) { inherit system; });
  pkgsFor = system: pkgsBySystem.${system} or (throw "utils: unsupported system ${system}");
  forAllSystems = f: lib.mapAttrs (_: f) pkgsBySystem;
  treefmtFor =
    pkgs:
    (inputs.treefmt-nix.lib.evalModule pkgs {
      projectRootFile = "flake.nix";
      programs.nixfmt.enable = true;
    }).config.build.wrapper;
in
{
  inherit systems allSystems nixpkgsFor pkgsFor forAllSystems treefmtFor;
}
