{ pkgs, lib, fetchFromGitHub, makeRustPlatform, rust-overlay, ... }:
let
  version = "1.19.0";
  rustPlatform = makeRustPlatform {
    cargo = rust-overlay.packages.aarch64-darwin.rust-nightly_2024-07-20;
    rustc = rust-overlay.packages.aarch64-darwin.rust-nightly_2024-07-20;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "starship-zmod";
  version = "1.19.0";
  src = pkgs.lib.cleanSource ./.;

  nativeBuildInputs = with pkgs; [ cmake ];

  buildInputs = with pkgs; [] ++ lib.optionals stdenv.isDarwin (with pkgs.darwin.apple_sdk; [
    frameworks.Cocoa
  ]);

  RUSTFLAGS = "-C link-arg=-undefined -C link-arg=dynamic_lookup";

  cargoLock = {
    lockFile = ./Cargo.lock;
    allowBuiltinFetchGit = false;
  };

  meta = {
    description = "";
    license = lib.licenses.unlicense;
    maintainers = [ "jw910731" ];
  };
}
