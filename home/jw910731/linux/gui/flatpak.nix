{ pkgs, ... }:
{
  services.flatpak = {
    uninstallUnmanaged = true;
    packages = [
      "com.discordapp.Discord"
      "com.valvesoftware.Steam"
      "org.kde.keepsecret"
      "org.localsend.localsend_app"
    ];
  };
}
