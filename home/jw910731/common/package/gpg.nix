{ pkgs, lib, ... }:
let
    pubkeys = [
        # Yubikey main
        {
            fingerprint = "a988c648ffb9e3affb6b80894057734400eda14e";
            pkHash = "sha256-Hd6hBlqqvDRwnPxGqj+lLA++wHX8sNb3rwNOqJ4nZcU=";
        }
        # Yubikey spare
        {
            fingerprint ="ea801549822d7a3c31abb2b796e25a197910e627";
            pkHash = "sha256-Fx7lFG+ZpXLSABa43rRCmNrX64l7C2tiiAckt+M8V0U=";
        } 
    ];
in {
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;

    publicKeys = lib.map (v: {
        source = (pkgs.fetchurl ({
            url = "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x${v.fingerprint}";
            hash = v.pkHash;
        })).outPath;
        trust = "ultimate";
    }) pubkeys;

    settings = {
      keyserver = "hkp://keyserver.ubuntu.com";
    };
  };

  services.gpg-agent = {
    enableSshSupport = false;
    enableExtraSocket = true;
    enableZshIntegration = true;
    sshKeys = lib.map (v: lib.toUpper v.fingerprint) pubkeys;
  };
}
