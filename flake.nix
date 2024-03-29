{
  description = "jw910731's NixOS Flake";

  inputs = {
    # NixPKG
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nil LSP
    nil.url = "github:oxalica/nil";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
  {
    nixosConfigurations = {
      "linux-host" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./system/linux-host/configuration.nix
        ];
      };
    };
  };
}
