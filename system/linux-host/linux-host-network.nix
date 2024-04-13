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
    allowedTCPPorts = [9345 6443 80 443 22];
    extraCommands=''
      iptables -A nixos-fw -p all -s 192.168.0.0/24 -j nixos-fw-accept
    '';
  };

  services.openssh.listenAddresses = [
    {
      addr = "0.0.0.0";
      port = 10022;
    }
  ];

  networking.networkmanager.unmanaged = ["cali*" "flannel*"];
}