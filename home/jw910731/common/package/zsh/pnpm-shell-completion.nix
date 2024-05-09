{ pkgs, naersk, ...}:
let
  naersk' = pkgs.callPackage naersk {}; 
in
naersk'.buildPackage rec {
  pname = "pnpm-shell-completion";
  version = "v0.5.3";

  src = pkgs.fetchFromGitHub {
    owner = "g-plane";
    repo = "pnpm-shell-completion";
    rev = version;
    hash = "sha256-UKuAUN1uGNy/1Fm4vXaTWBClHgda+Vns9C4ugfHm+0s=";
  };

  postInstall = ''
    cp ./pnpm-shell-completion.plugin.zsh $out/
    ln -s ./bin/pnpm-shell-completion $out/
  '';
}