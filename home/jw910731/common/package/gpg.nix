{ pkgs, lib, ... }:
let
  pubkeys = [
    # Yubikey main
    {
      fingerprint = "a988c648ffb9e3affb6b80894057734400eda14e";
      pkHash = "sha256-Tzk91FXJ/DKwEDNUAmzVQSEBUQa+KXvHRYLg1CdRCw0=";
    }
    # Yubikey spare
    {
      fingerprint = "ea801549822d7a3c31abb2b796e25a197910e627";
      pkHash = "sha256-6AQBxyS1tztbuIATHSq9FtIZ8+N3q+u1V83vHLFvdbM=";
    }
  ];
in
{
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;

    publicKeys = lib.map (v: {
      source =
        (pkgs.fetchurl ({
          url = "https://keys.openpgp.org/vks/v1/by-fingerprint/${v.fingerprint}";
          hash = v.pkHash;
        })).outPath;
      trust = null;
    }) pubkeys;
  };

  services.gpg-agent = {
    enableSshSupport = false;
    enableExtraSocket = true;
    enableZshIntegration = true;
    sshKeys = lib.map (v: lib.toUpper v.fingerprint) pubkeys;
  };
}
