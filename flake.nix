{
  description = "jw910731's NixOS Flake";

  inputs = {
    # NixPKG
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixos-apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # formatter
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    numlockfixd = {
      url = "github:jw910731/numlockfixd";
    };

    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-doom-emacs-unstraightened-darwin = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code-darwin = {
      url = "github:sadjow/claude-code-nix";
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
      numlockfixd,
      nix-doom-emacs-unstraightened,
      nix-doom-emacs-unstraightened-darwin,
      claude-code,
      claude-code-darwin,
      ...
    }:
    let
      lib = nixpkgs.lib;
      linuxOverlays = [ 
        nix-doom-emacs-unstraightened.overlays.default
        claude-code.overlays.default
      ];
      darwinOverlays = [
        nix-doom-emacs-unstraightened-darwin.overlays.default
        claude-code-darwin.overlays.default
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
          {
            programs.zsh.shellAliases = {
              "ggg" = "sudo graidctl";
            };
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
          "asahi" = moduleModifier nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              nixos-apple-silicon.nixosModules.default
              ./system/asahi/configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.sharedModules = [
                  nix-doom-emacs-unstraightened.homeModule
                ];

                home-manager.users = {
                  jw910731 = nixpkgs.lib.mkMerge [
                    (import ./home/jw910731/linux-gui.nix)
                    (import ./home/jw910731/1p-sign.nix)
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
          "macbook" =
            let
              system = "aarch64-darwin";
            in
            moduleModifier darwin.lib.darwinSystem {
              inherit system;
              modules = [
                ./system/macbook
                home-manager-darwin.darwinModules.home-manager
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
                (darwinHostSetup {
                  hostName = "jw910731-MacBook-Air";
                  computerName = "jw910731's Macbook Air";
                })
              ];
            };
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
