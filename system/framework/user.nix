{ pkgs, ... }:
{
  security.pam.services.jw910731.kwallet.enable = true;
  users.users.jw910731 = {
    isNormalUser = true;
    description = "Jerry Wu";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
