{
  description = "jw910731's NixOS Flake";

  inputs = {
    # NixPKG
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # formatter
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-darwin,
      darwin,
      nixos-apple-silicon,
      home-manager,
      home-manager-darwin,
      treefmt-nix,
      ...
    }:
    {
      # Formatter settings
      formatter =
        let
          formatter =
            pkgs:
            (treefmt-nix.lib.evalModule pkgs {
              projectRootFile = "flake.nix";
              programs.nixfmt.enable = true;
            }).config.build.wrapper;
        in
        (nixpkgs-darwin.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" ] (
          system: formatter (import nixpkgs-darwin { inherit system; })
        ))
        // (nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
          system: formatter (import nixpkgs { inherit system; })
        ));

      # NixOS configs
      nixosConfigurations = {
        "linux-host" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [

            ./system/linux-host/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users = {
                jw910731 = nixpkgs.lib.mkMerge [
                  (import ./home/jw910731/linux.nix)
                  (import ./home/jw910731/yubi-sign.nix)
                ];
              };
            }
          ];
        };
        "utm" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./system/utm/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users = {
                jw910731 = nixpkgs.lib.mkMerge [
                  (import ./home/jw910731/linux-gui.nix)
                  (import ./home/jw910731/1p-sign.nix)
                ];
              };
            }
          ];
        };
        "asahi" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixos-apple-silicon.nixosModules.default
            ./system/asahi/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users = {
                jw910731 = nixpkgs.lib.mkMerge [
                  (import ./home/jw910731/linux-gui.nix)
                  (import ./home/jw910731/1p-sign.nix)
                ];
              };
            }
          ];
        };
        "nixos-orbstack" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./system/orbstack/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.users = {
                jw910731 = nixpkgs.lib.mkMerge [
                  (import ./home/jw910731/linux.nix)
                  (import ./home/jw910731/1p-sign.nix)
                ];
              };
            }
          ];
        };
      };

      # Darwin configs
      darwinConfigurations = {
        "macbook" =
          let
            system = "aarch64-darwin";
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
              }
            ];
          };
        "macbook-work" =
          let
            system = "x86_64-darwin";
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
              }
            ];
          };
      };
    };
}
