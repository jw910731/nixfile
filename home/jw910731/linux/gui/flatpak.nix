{ pkgs, ... }:
{
  services.flatpak = {
    uninstallUnmanaged = true;
    packages = [
      "com.discordapp.Discord"
      "com.valvesoftware.Steam"
    ];
  };
}
