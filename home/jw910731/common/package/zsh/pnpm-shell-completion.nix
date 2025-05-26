{ pkgs, ... }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "pnpm-shell-completion";
  version = "v0.5.4";

  src = pkgs.fetchFromGitHub {
    owner = "g-plane";
    repo = "pnpm-shell-completion";
    rev = version;
    hash = "sha256-bc2ZVHQF+lSAmhy/fvdiVfg9uzPPcXYrtiNChjkjHtA=";
  };

  cargoHash = "sha256-JL9bWVHmdSktOEF70WMOmZKdZwO/gNDp0GPDMYteR1E=";

  postInstall = ''
    cp ./pnpm-shell-completion.plugin.zsh $out/
    ln -s ./bin/pnpm-shell-completion $out/
  '';
}
