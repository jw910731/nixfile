{ pkgs, ... }:
{
  networking.hostName = "jw910731-framework"; # Define your hostname.

  # networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
  };
}
