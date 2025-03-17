final: prev:
let
  go_version = "1.22.12";
  go = prev.go_1_22.overrideAttrs rec {
    version = go_version;
    src = prev.fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-ASp+HzfzYsCRjB36MzRFisLaFijEuc9NnKAtuYbhfXE=";
    };
  };
  buildGoModule = prev.buildGo122Module.override {
    inherit go;
  };

in
{
  rke2 = prev.rke2.override {
    buildGoModule =
      args:
      buildGoModule (
        args
        // rec {
          nativeBuildInputs = [
            prev.yq-go
            prev.curl
            prev.git
          ];
          version = "1.31.6+rke2r1";

          src = prev.fetchFromGitHub {
            owner = "rancher";
            repo = args.pname;
            rev = "v${version}";
            hash = "sha256-5k2KZA37HXtTdVGvhGQ0IBuddokYL/HwwbcysRJMAC4=";
            leaveDotGit = true;
          };

          vendorHash = "sha256-ug1dO4t/QfPpg3mobCIJWb8/MERUoP9tEMlKRKZigXo=";

          postPatch = ''
            # Patch the build scripts so they work in the Nix build environment.
            patchShebangs ./scripts

            # Disable the static build as it breaks.
            sed -e 's/STATIC_FLAGS=.*/STATIC_FLAGS=/g' -i scripts/build-binary
            sed -e 's/VERSION_GOLANG=.*/VERSION_GOLANG=go${go_version}/g' -i scripts/version.sh
          '';

          buildPhase = ''
            GITHUB_ACTION_TAG="v${version}" ./scripts/build-binary
          '';

          installPhase = ''
            install -D ./bin/rke2 $out/bin/rke2
          '';
        }
      );
  };
}
