{ pkgs, ... }:
{
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;

    settings = {
      keyserver = "hkp://keyserver.ubuntu.com";
    };
  };

  services.gpg-agent = {
    enableSshSupport = false;
    enableExtraSocket = true;
    enableZshIntegration = true;
    sshKeys = [ "A988C648FFB9E3AFFB6B80894057734400EDA14E" ];
  };
}
