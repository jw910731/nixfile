{pkgs, ...}:
{
  users.users.jw910731 = {
    isNormalUser = true;
    description = "Jerry Wu";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
}