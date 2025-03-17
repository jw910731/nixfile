final: prev:
let
  go_version = "1.21.9";
  go = prev.go_1_21.overrideAttrs rec {
    version = go_version;
    src = prev.fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-WPDFztRaABK84v96nfA+Eoq8yIGOur5QJ7uSuv4g5CE=";
    };
  };
  buildGoModule = prev.buildGo121Module.override {
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
          version = "1.28.10+rke2r1";

          src = prev.fetchFromGitHub {
            owner = "rancher";
            repo = args.pname;
            rev = "v${version}";
            hash = "sha256-hPAmsXf+06tgiV/qtfZcIS+meAIyN7ST81t2/T4Rd/Q=";
            leaveDotGit = true;
          };

          vendorHash = "sha256-iidkTSrrHyW5ZEouzHAWUwCC9nplGz1v/E9bM2lMPeM=";

          postPatch = ''
            # Patch the build scripts so they work in the Nix build environment.
            patchShebangs ./scripts

            # Disable the static build as it breaks.
            sed -e 's/STATIC_FLAGS=.*/STATIC_FLAGS=/g' -i scripts/build-binary
            sed -e 's/VERSION_GOLANG=.*/VERSION_GOLANG=go${go_version}/g' -i scripts/version.sh
          '';

          buildPhase = ''
            DRONE_TAG="v${version}" ./scripts/build-binary
          '';

          installPhase = ''
            install -D ./bin/rke2 $out/bin/rke2
          '';
        }
      );
  };
}
