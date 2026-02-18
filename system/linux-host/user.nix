{ pkgs, ... }:
{
  users.users.jw910731 = {
    isNormalUser = true;
    description = "Jerry Wu";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
    ];
    shell = pkgs.zsh;
  };
}
