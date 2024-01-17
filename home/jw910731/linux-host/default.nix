{ config, pkgs, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jw910731 = {
    isNormalUser = true;
    description = "Jerry Wu";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      brave
      obs-studio
    ];
  };
}