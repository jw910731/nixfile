{ pkgs, mypkgs, lib, ... }:
pkgs.zsh.overrideAttrs (finalAttrs: previousAttrs: {
  postInstall = previousAttrs.postInstall + ''
    cp ${lib.getBin mypkgs.starship-zmod}/lib/libstarship_zmod.dylib $out/lib/zsh/5.9/starship.so
  '';
})
