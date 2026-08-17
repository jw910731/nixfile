{ pkgs, ... }:
{
  networking.hostName = "jw910731-framework"; # Define your hostname.

  # networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
    };
  };
}
