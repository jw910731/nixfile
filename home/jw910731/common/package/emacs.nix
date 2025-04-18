{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.emacs = {
    enable = true;
    # Patch emacs on darwin, see https://github.com/NixOS/nixpkgs/issues/395169
    package =
      if pkgs.stdenv.targetPlatform.isDarwin then
        pkgs.emacs-nox.override { withNativeCompilation = false; }
      else
        pkgs.emacs-nox;
    extraPackages = epkgs: [ epkgs.vterm ];
  };
  home.packages = with pkgs; [
    ripgrep
    coreutils # basic GNU utilities
    fd
  ];

  home.activation.install-doom = lib.hm.dag.entryAfter [ "installPackages" ] ''
    if ! [ -d "${config.xdg.configHome}/emacs" ]; then
      $DRY_RUN_CMD ${lib.getExe pkgs.git} clone $VERBOSE_ARG --depth=1 --single-branch "https://github.com/doomemacs/doomemacs.git" "${config.xdg.configHome}/emacs"
    fi
  '';

  xdg.configFile."doom" = {
    source = ./doom;
  };
}
