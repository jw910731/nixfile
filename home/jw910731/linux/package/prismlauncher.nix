{config, ...}:
{
  xdg.dataFile."PrismLauncher.instances" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Game/Minecraft/client/instances";
    target = "./PrismLauncher/instances";
  };
  xdg.dataFile."PrismLauncher.icons"= {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Game/Minecraft/client/icons";
    target = "./PrismLauncher/icons";
  };
}