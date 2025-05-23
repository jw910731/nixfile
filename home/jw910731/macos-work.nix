{ lib, pkgs, config, ... }:
{
  imports = [
    ./common

    ./darwin
  ];
  home.username = "jw910731";
  home.homeDirectory = lib.mkForce "/Users/jw910731";
  
  # Auto managed by internal tool
  programs.git = {
    # Sign
    signing = {
      signByDefault = true;
      key = null;
    };
    extraConfig.gpg = {
      format = "x509";
      x509.program = "/usr/local/bin/ac-sign";
    };
  };

  home.packages = with pkgs; [
  ];
}
