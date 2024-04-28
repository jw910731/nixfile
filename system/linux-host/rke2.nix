final: prev:
let
  go_version = "1.21.7";
  go = prev.go.overrideAttrs rec {
    version = go_version;
    src = prev.fetchurl {
      url = "https://go.dev/dl/go${version}.src.tar.gz";
      hash = "sha256-ABl6sg8zgTgyv/Yv2TzKHEKgjMaJoypmcspJWRlZv/Y=";
    };
  };
  buildGoModule = prev.buildGo121Module.override {
    inherit go;
  };

in
{
  rke2 = prev.rke2.override {
    buildGoModule = args: buildGoModule (args // rec {
      nativeBuildInputs = [ prev.yq-go prev.curl prev.git ];
      version = "1.27.11+rke2r1";

      src = prev.fetchFromGitHub {
        owner = "rancher";
        repo = args.pname;
        rev = "v${version}";
        hash = "sha256-tCX/fatYqG/TLd33oY4+XkEL3L9L2RqZNteMNN7XxmE=";
        leaveDotGit = true;
      };

      vendorHash = "sha256-elK0gPZmCW7kfGmnXmkJ2C6GFGMb9jn4Hla47PeqUJI=";

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
    });
  };
}

