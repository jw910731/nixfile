{
  description = "jw910731's NixOS Flake";

  inputs = {
    # Core: nixpkgs channels
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # nixpkgs-unstable: only consumed by linuxOverlays (zed-editor)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Common: one per platform, each following its platform's nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-doom-emacs-unstraightened-darwin = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    # llm-agents: no follows on purpose (keeps upstream binary cache hits); used on both platforms
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };

    # Utility: formatter / devShell
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Darwin only
    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    numlockfixd = {
      url = "github:jw910731/numlockfixd";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Linux only
    ## system modules
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    intel-lpmd-flake = {
      url = "github:dmfrpro/intel-lpmd-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openlogi = {
      url = "github:AprilNEA/OpenLogi?dir=packaging";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## desktop home-manager
    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.8.0";
    vicinae = {
      url = "github:vicinaehq/vicinae";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-darwin,
      darwin,
      home-manager,
      home-manager-darwin,
      treefmt-nix,
      numlockfixd,
      nix-doom-emacs-unstraightened,
      nix-doom-emacs-unstraightened-darwin,
      llm-agents,
      helium-flake,
      nixos-hardware,
      lanzaboote,
      nix-flatpak,
      intel-lpmd-flake,
      vicinae,
      vicinae-extensions,
      noctalia,
      openlogi,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      linuxOverlays = [
        nix-doom-emacs-unstraightened.overlays.default
        helium-flake.overlays.default

        (final: prev: {
          zed-editor = nixpkgs-unstable.legacyPackages.${prev.stdenv.system}.zed-editor;
          zed-editor-fhs = nixpkgs-unstable.legacyPackages.${prev.stdenv.system}.zed-editor-fhs;
        })
      ];
      darwinOverlays = [
        nix-doom-emacs-unstraightened-darwin.overlays.default
        (final: prev: {
          numlockfixd = numlockfixd.packages.${prev.stdenv.system}.numlockfixd;
        })
        (final: prev: {
          emacs-nox = prev.emacs-nox.override { withNativeCompilation = true; };
        })
      ];
      darwinHostSetup = (
        { hostName, computerName }:
        {
          networking.computerName = "${computerName}";
          networking.hostName = "${hostName}";
          system.defaults.smb.NetBIOSName = "${hostName}";
        }
      );

      moduleModifier' =
        overlays: systemFunc: systemAttrs:
        systemFunc (
          lib.attrsets.updateManyAttrsByPath [
            {
              path = [ "modules" ];
              update =
                modules:
                modules
                ++ [
                  { nixpkgs.overlays = overlays; }
                  {
                    home-manager.extraSpecialArgs = {
                      mylib = import ./lib lib;
                      inherit inputs;
                    };
                  }
                ];
            }
            {
              path = [ "specialArgs" ];
              update =
                specialArgs:
                specialArgs
                // {
                  mylib = import ./lib lib;
                  inherit inputs;
                };
            }
          ] (systemAttrs // { specialArgs = { }; })
        );

      utils = import ./flake/utils.nix { inherit inputs lib; };
    in
    {
      # Formatter settings
      formatter = utils.forAllSystems utils.treefmtFor;

      # Minimal shell for boostraping everything
      devShells = utils.forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [
            pkgs.nixd
            (utils.treefmtFor pkgs)
            pkgs.just
            pkgs.nh
          ];
        };
      });

      # NixOS configs
      nixosConfigurations =
        let
          moduleModifier = moduleModifier' linuxOverlays;
        in
        {
          "linux-host" = moduleModifier nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";

            modules = [
              ./system/linux-host/configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.sharedModules = [
                  nix-doom-emacs-unstraightened.homeModule
                ];

                home-manager.users = {
                  jw910731 = nixpkgs.lib.mkMerge [
                    (import ./home/jw910731/linux.nix)
                    (import ./home/jw910731/yubi-sign.nix)
                  ];
                };
              }
            ];
          };
          "framework" = moduleModifier nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";

            modules = [
              ./system/framework/configuration.nix
              nixos-hardware.nixosModules.framework-intel-core-ultra-series3
              intel-lpmd-flake.nixosModules.default
              vicinae.nixosModules.default
              lanzaboote.nixosModules.lanzaboote
              openlogi.nixosModules.default
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.sharedModules = [
                  nix-doom-emacs-unstraightened.homeModule
                  nix-flatpak.homeManagerModules.nix-flatpak
                  vicinae.homeManagerModules.default
                  helium-flake.homeModules.default
                  noctalia.homeModules.default
                ];

                home-manager.users = {
                  jw910731 = nixpkgs.lib.mkMerge [
                    (import ./home/jw910731/linux-gui.nix)
                    (import ./home/jw910731/1p-sign.nix)
                    { imports = [ ./home/jw910731/device/framework ]; }
                  ];
                };
              }
            ];
          };
        };

      # Darwin configs
      darwinConfigurations =
        let
          moduleModifier = moduleModifier' darwinOverlays;
        in
        {
          "macstudio" =
            let
              system = "aarch64-darwin";
            in
            moduleModifier darwin.lib.darwinSystem {
              inherit system;
              modules = [
                ./system/macstudio
                home-manager-darwin.darwinModules.home-manager
                (
                  { lib, ... }:
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.sharedModules = [
                      nix-doom-emacs-unstraightened-darwin.homeModule
                    ];

                    home-manager.users = {
                      jw910731 = import ./home/jw910731/macos.nix;
                    };
                  }
                )
                (darwinHostSetup {
                  hostName = "jw910731-Mac-Studio";
                  computerName = "jw910731's Mac Studio";
                })
              ];
            };
          "macmini" =
            let
              system = "aarch64-darwin";
            in
            moduleModifier darwin.lib.darwinSystem {
              inherit system;
              modules = [
                ./system/macmini
                home-manager-darwin.darwinModules.home-manager
                (
                  { lib, ... }:
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.sharedModules = [
                      nix-doom-emacs-unstraightened-darwin.homeModule
                    ];

                    home-manager.users = {
                      jw910731 = import ./home/jw910731/macos.nix;
                    };
                  }
                )
                (darwinHostSetup {
                  hostName = "MacMini";
                  computerName = "MacMini";
                })
              ];
            };
          "macbook-work" =
            let
              system = "aarch64-darwin";
            in
            moduleModifier darwin.lib.darwinSystem {
              inherit system;
              modules = [
                ./system/macbook-work
                home-manager-darwin.darwinModules.home-manager
                (
                  { lib, ... }:
                  {
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.sharedModules = [
                      nix-doom-emacs-unstraightened-darwin.homeModule
                    ];

                    home-manager.users = {
                      "jw910731" = lib.mkMerge [
                        (import ./home/jw910731/macos-work.nix)
                        {
                          home.username = "jw910731";
                          home.homeDirectory = lib.mkForce "/Users/jw910731";
                        }
                      ];
                    };
                  }
                )
                (darwinHostSetup {
                  hostName = "jerrywu-macbook";
                  computerName = "jerrywu's Macbook";
                })
              ];
            };
        };
    };
}
