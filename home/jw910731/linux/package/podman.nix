{ ... }:
{
  services.podman = {
    enable = true;
    settings.containers = {
      engine.compose_providers = [ "podman-compose" ];
    };
  };
}
