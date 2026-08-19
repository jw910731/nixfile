{
  description = "jw910731's NixOS Flake";

  inputs = {
    # NixPKG
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    # formatter
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Darwin Only
    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    numlockfixd = {
      url = "github:jw910731/numlockfixd";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Darwin & Linux
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-doom-emacs-unstraightened-darwin = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents-darwin = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Linux Only
    helium-flake = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:oxcl/nix-flake-helium-browser";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";

    intel-lpmd-flake = {
      url = "github:dmfrpro/intel-lpmd-flake";
      inputs.nixpkgs.follows = "nixpkgs";
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
      llm-agents-darwin,
      helium-flake,
      nixos-hardware,
      lanzaboote,
      nix-flatpak,
      intel-lpmd-flake,
      ...
    }:
    let
      lib = nixpkgs.lib;
      linuxOverlays = [
        nix-doom-emacs-unstraightened.overlays.default
        llm-agents.overlays.shared-nixpkgs
        helium-flake.overlays.default
        (final: prev: {
          zed-editor = nixpkgs-unstable.legacyPackages.${prev.stdenv.system}.zed-editor;
          zed-editor-fhs = nixpkgs-unstable.legacyPackages.${prev.stdenv.system}.zed-editor-fhs;
        })
        (final: prev: {
          fw-ectool = prev.callPackage ./system/framework/fw-ectool.nix {};
        })
      ];
      darwinOverlays = [
        nix-doom-emacs-unstraightened-darwin.overlays.default
        llm-agents-darwin.overlays.shared-nixpkgs
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
              update = modules: modules ++ [ { nixpkgs.overlays = overlays; } ];
            }
            {
              path = [ "specialArgs" ];
              update = specialArgs: specialArgs // { mylib = import ./lib lib; };
            }
          ] (systemAttrs // { specialArgs = { }; })
        );

      pkgs' =
        (lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" ] (
          system: (import nixpkgs-darwin { inherit system; })
        ))
        // (lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: (import nixpkgs { inherit system; })));
      formatter =
        pkgs:
        (treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        }).config.build.wrapper;
    in
    {
      # Formatter settings
      formatter = (lib.mapAttrs (_: pkgs: formatter pkgs) pkgs');

      # Minimal shell for boostraping everything
      devShells =
        let
          supportedSystems = [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ];
          forEachSupportedSystem =
            f:
            nixpkgs.lib.genAttrs supportedSystems (
              system:
              f {
                pkgs = pkgs'."${system}";
              }
            );
        in
        forEachSupportedSystem (
          { pkgs }:
          {
            default = pkgs.mkShellNoCC {
              packages = [
                pkgs.nixd
                (formatter pkgs)
                pkgs.just
                pkgs.nh
              ];
            };
          }
        );

      homeConfigurations."jw910731" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config = {
            allowUnfree = true;
          };
        };
        modules = [
          nix-doom-emacs-unstraightened.homeModule
          (import ./home/jw910731/linux.nix)
          (import ./home/jw910731/yubi-sign.nix)
          { nixpkgs.overlays = linuxOverlays; }
          {
            programs.zsh.shellAliases = {
              "ggg" = "sudo graidctl";
            };
            targets.genericLinux.enable = true;
            programs.git.settings.user = {
              name = lib.mkForce "Jerry Wu";
              email = lib.mkForce "jerry.wu@graidtech.com";
            };
          }
        ];
      };

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
              lanzaboote.nixosModules.lanzaboote
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.sharedModules = [
                  nix-doom-emacs-unstraightened.homeModule
                  nix-flatpak.homeManagerModules.nix-flatpak
                ];

                home-manager.users = {
                  jw910731 = nixpkgs.lib.mkMerge [
                    (import ./home/jw910731/linux-gui.nix)
                    (import ./home/jw910731/1p-sign.nix)
                    {
                      imports = [ ./home/jw910731/device/framework ];
                    }
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
