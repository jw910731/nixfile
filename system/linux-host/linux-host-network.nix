{pkgs, ...}:
{
  networking.hostName = "jw910731-nixos"; # Define your hostname.
  networking.interfaces.enp6s0 = {
    wakeOnLan = {
      enable = true;
      policy = ["magic"];
    };
    useDHCP = true;
  };

  # networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["wlp5s0"];
    allowedTCPPorts = [9345 6443 80 443];
    extraCommands="iptables -A nixos-fw -p all -s 192.168.0.0/24 -j nixos-fw-accept";
  };

  networking.networkmanager.unmanaged = ["cali*" "flannel*"];

  # Linux Host Network packages
  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  services.cloudflared = {
    enable = true;
    tunnels = {
      "9abf9847-04b5-4aa9-8d79-2fbd8a2e5ca6" = {
        credentialsFile = "/etc/cloudflared/credentials.json";
        default = "http_status:404";
      };
    };
  };
}