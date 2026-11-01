# Host builders: role -> external NixOS modules + Home Manager sharedModules.
{
  inputs,
  lib,
  linuxOverlays,
  darwinOverlays,
  moduleModifier',
}:
let
  user = "jw910731";

  # Home Manager wiring shared by every host.
  hmBase =
    { sharedModules, homeModules }:
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.sharedModules = sharedModules;
      home-manager.users.${user} = lib.mkMerge homeModules;
    };

  linuxRoles = {
    server = {
      nixosModules = [ ];
      hmModules = [ inputs.nix-doom-emacs-unstraightened.homeModule ];
    };
    desktop = {
      nixosModules = [
        inputs.vicinae.nixosModules.default
        inputs.openlogi.nixosModules.default
      ];
      hmModules = [
        inputs.nix-doom-emacs-unstraightened.homeModule
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.vicinae.homeManagerModules.default
        inputs.helium-flake.homeModules.default
        inputs.noctalia.homeModules.default
      ];
    };
  };

  darwinHmModules = [ inputs.nix-doom-emacs-unstraightened-darwin.homeModule ];

  # nix-darwin does not derive the HM home directory; pin it for every Mac.
  darwinUser =
    { lib, ... }:
    {
      home.username = user;
      home.homeDirectory = lib.mkForce "/Users/${user}";
    };

  darwinHostSetup =
    { hostName, computerName }:
    {
      networking.computerName = "${computerName}";
      networking.hostName = "${hostName}";
      system.defaults.smb.NetBIOSName = "${hostName}";
    };
in
{
  mkNixos =
    {
      system,
      role,
      modules,
      homeModules,
    }:
    let
      r = linuxRoles.${role} or (throw "mkNixos: unknown role '${role}' (expected: server, desktop)");
    in
    moduleModifier' linuxOverlays lib.nixosSystem {
      inherit system;
      modules =
        modules
        ++ r.nixosModules
        ++ [
          inputs.home-manager.nixosModules.home-manager
          (hmBase {
            sharedModules = r.hmModules;
            inherit homeModules;
          })
        ];
    };

  mkDarwin =
    {
      system,
      hostName,
      computerName,
      modules,
      homeModules,
    }:
    moduleModifier' darwinOverlays inputs.darwin.lib.darwinSystem {
      inherit system;
      modules = modules ++ [
        inputs.home-manager-darwin.darwinModules.home-manager
        (hmBase {
          sharedModules = darwinHmModules;
          homeModules = homeModules ++ [ darwinUser ];
        })
        (darwinHostSetup { inherit hostName computerName; })
      ];
    };
}
