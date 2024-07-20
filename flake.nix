{
  description = "jw910731's NixOS Flake";

  inputs = {
    # NixPKG
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Rust builder
    naersk.url = "github:nix-community/naersk";

    mypkgs.url = "path:./pkgs";
    mypkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, nixpkgs-darwin, home-manager-darwin, darwin, naersk, ... }@inputs:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      formatter.aarch64-darwin = nixpkgs-darwin.legacyPackages.aarch64-darwin.nixpkgs-fmt;
      formatter.x86_64-darwin = nixpkgs-darwin.legacyPackages.x86_64-darwin.nixpkgs-fmt;
      nixosConfigurations = {
        "linux-host" =
          let
	          system = "x86_64-linux";
            mypkgs = inputs.mypkgs.packages.${system};
          in
          nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./system/linux-host/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users = {
                jw910731 = import ./home/jw910731/linux.nix;
              };
              home-manager.extraSpecialArgs = {
                naersk = inputs.naersk;
                inherit mypkgs;
              };
            }
          ];
        };
      };
      darwinConfigurations = {
        "macbook" =
          let
            system = "aarch64-darwin";
            mypkgs = inputs.mypkgs.packages.${system};
          in
          darwin.lib.darwinSystem {
            inherit system;
            modules = [
              ./system/macbook
              home-manager-darwin.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.users = {
                  jw910731 = import ./home/jw910731/macos.nix;
                };
                home-manager.extraSpecialArgs = {
                  naersk = inputs.naersk;
                  inherit mypkgs;
                };
              }
            ];
          };
        "macbook-work" =
          let
            system = "x86_64-darwin";
            mypkgs = inputs.mypkgs.packages.${system};
          in
          darwin.lib.darwinSystem {
            inherit system;
            modules = [
              ./system/macbook-work
              home-manager-darwin.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.users = {
                  "jerry.wu" = import ./home/jw910731/macos-work.nix;
                };
                home-manager.extraSpecialArgs = {
                  naersk = inputs.naersk;
                  inherit mypkgs;
                };
              }
            ];
          };
      };
    };
}
