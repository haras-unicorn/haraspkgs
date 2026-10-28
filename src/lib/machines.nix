{ lib, selfLib, ... }:

{
  self.lib.machines = {
    nixModule =
      { lib, pkgs, ... }:
      {
        nix.package = lib.mkDefault pkgs.nix;

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            # NOTE: needed for uid-range
            "auto-allocate-uids"
            # NOTE: needed for uid-range
            "cgroups"
          ];

          system-features = [
            # NOTE: defaults
            "benchmark"
            "big-parallel"
            "kvm"
            "nixos-test"
            # NOTE: needed for nixos container tests
            "uid-range"
          ];

          # NOTE: needed for uid-range
          auto-allocate-uids = true;

          # NOTE: default is [ "*" ]
          allowed-users = [
            "root"
            "@wheel"
          ];

          # NOTE: default is [ ]
          trusted-users = [
            "root"
            "@wheel"
          ];
        };
      };

    makeNixosConfigurationAttrs =
      {
        specialArgs,
        nixpkgs,
        home-manager,
        config,
        overlays,
        modules,
      }:
      builtins.mapAttrs (
        name: module:
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            {
              _file = ./machines.nix;
              key = ./machines.nix;

              imports = [
                home-manager.nixosModules.home-manager
                selfLib.machines.nixModule
                selfLib.cuda.hostModule
                module
              ];

              nix.registry.nixpkgs.flake = nixpkgs;

              nixpkgs = { inherit config overlays; };

              networking.hostName = lib.mkDefault name;

              home-manager.extraSpecialArgs = specialArgs;
              home-manager.sharedModules = [
                {
                  home.stateVersion = lib.mkDefault "26.05";
                }
              ];

              system.stateVersion = lib.mkDefault "26.05";
            }
          ];
        }
      ) modules;

    makeHomeConfigurationAttrs =
      {
        specialArgs,
        nixpkgs,
        home-manager,
        config,
        overlays,
        modules,
      }:
      builtins.mapAttrs (
        name: module:
        home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = specialArgs;

          # NOTE: a minimal stub that Home Manager needs
          # `nixpkgs.system` is the canonical way to set the system
          # same as in NixOS
          pkgs = {
            inherit (nixpkgs) lib;
            path = nixpkgs.outPath;
            config = { };
            overlays = [ ];
            stdenv.hostPlatform.system = "x86_64-linux"; # NOTE: home-manager pkgs stub
            nix = nixpkgs.legacyPackages.x86_64-linux.nix; # NOTE: home-manager pkgs stub
          };

          modules = [
            {
              _file = ./machines.nix;
              key = ./machines.nix;

              imports = [
                selfLib.machines.nixModule
                module
              ];

              nixpkgs = { inherit config overlays; };

              home.stateVersion = lib.mkDefault "26.05";
            }
          ];
        }
      ) modules;
  };
}
