{
  description = "jw910731's NixOS Flake";

  # Binary caches scoped to this flake (not written to system nix.conf).
  # Requires the invoking user to be in trusted-users; accept with
  # --accept-flake-config or answer the prompt.
  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
      "https://vicinae.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

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
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
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
    inputs@{ nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      linuxOverlays = [
        inputs.nix-doom-emacs-unstraightened.overlays.default
        inputs.helium-flake.overlays.default

        (final: prev: {
          zed-editor = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.system}.zed-editor;
          zed-editor-fhs = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.system}.zed-editor-fhs;
        })
      ];
      darwinOverlays = [
        inputs.nix-doom-emacs-unstraightened-darwin.overlays.default
        (final: prev: {
          numlockfixd = inputs.numlockfixd.packages.${prev.stdenv.system}.numlockfixd;
        })
        (final: prev: {
          emacs-nox = prev.emacs-nox.override { withNativeCompilation = true; };
        })
      ];
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

      hosts = import ./flake/hosts.nix {
        inherit
          inputs
          lib
          linuxOverlays
          darwinOverlays
          moduleModifier'
          ;
      };
      inherit (hosts) mkNixos mkDarwin;

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
      nixosConfigurations = {
        "linux-host" = mkNixos {
          system = "x86_64-linux";
          role = "server";
          modules = [ ./system/linux-host/configuration.nix ];
          homeModules = [
            ./home/jw910731/linux.nix
            ./home/jw910731/yubi-sign.nix
          ];
        };
        "framework" = mkNixos {
          system = "x86_64-linux";
          role = "desktop";
          modules = [
            ./system/framework/configuration.nix
            inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
            inputs.intel-lpmd-flake.nixosModules.default
            inputs.lanzaboote.nixosModules.lanzaboote
          ];
          homeModules = [
            ./home/jw910731/linux-gui.nix
            ./home/jw910731/1p-sign.nix
            { imports = [ ./home/jw910731/device/framework ]; }
          ];
        };
        "asahi" = mkNixos {
          system = "aarch64-linux";
          role = "desktop";
          modules = [
            ./system/asahi/configuration.nix
            inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
          ];
          homeModules = [
            ./home/jw910731/linux-gui.nix
            ./home/jw910731/1p-sign.nix
            { imports = [ ./home/jw910731/device/asahi ]; }
          ];
        };
      };

      # Darwin configs
      darwinConfigurations = {
        "macstudio" = mkDarwin {
          system = "aarch64-darwin";
          hostName = "jw910731-Mac-Studio";
          computerName = "jw910731's Mac Studio";
          modules = [ ./system/macstudio ];
          homeModules = [ ./home/jw910731/macos.nix ];
        };
        "macmini" = mkDarwin {
          system = "aarch64-darwin";
          hostName = "MacMini";
          computerName = "MacMini";
          modules = [ ./system/macmini ];
          homeModules = [ ./home/jw910731/macos.nix ];
        };
        "macbook-work" = mkDarwin {
          system = "aarch64-darwin";
          hostName = "jerrywu-macbook";
          computerName = "jerrywu's Macbook";
          modules = [ ./system/macbook-work ];
          homeModules = [ ./home/jw910731/macos-work.nix ];
        };
      };
    };
}
