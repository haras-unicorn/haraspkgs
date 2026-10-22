{ selfLib, ... }:

{
  self.flakeModules.machines = {
    self = false;
    flake = true;
    value =
      {
        lib,
        config,
        specialArgs,
        ...
      }:
      {
        options.self = {
          nixosModules = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule (selfLib.lib.selfSubmodule lib.types.deferredModule));
            default.default = {
              value = { };
            };
            description = "NixOS modules.";
          };

          homeModules = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule (selfLib.lib.selfSubmodule lib.types.deferredModule));
            default.default = {
              value = { };
            };
            description = "Home Manager modules.";
          };

          nixosConfigurations = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule (selfLib.lib.selfSubmodule lib.types.deferredModule));
            default = { };
            description = "NixOS modules as NixOS configurations";
          };

          homeConfigurations = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule (selfLib.lib.selfSubmodule lib.types.deferredModule));
            default = { };
            description = "Home Manager modules as Home configurations";
          };
        };

        config =
          let
            selfNixosModules = builtins.mapAttrs (_: module: module.value) (
              selfLib.lib.filterAttrsByKey "self" true config.self.nixosModules
            );

            selfHomeModules = builtins.mapAttrs (_: module: module.value) (
              selfLib.lib.filterAttrsByKey "self" true config.self.homeModules
            );

            makeMachineAttrs =
              for:
              assert for == "self" || for == "flake";
              let
                key = for;
                default = for == "self";
              in
              {
                nixosModules = selfLib.lib.makeModuleAttrs (
                  selfLib.lib.filterAttrsByKey key default config.self.nixosModules
                );
                homeModules = selfLib.lib.makeModuleAttrs (
                  selfLib.lib.filterAttrsByKey key default config.self.homeModules
                );

                nixosConfigurations = selfLib.machines.makeNixosConfigurationAttrs {
                  inherit specialArgs;
                  inherit (config.self.lib.pkgs)
                    nixpkgs
                    home-manager
                    config
                    overlays
                    ;

                  modules =
                    builtins.mapAttrs
                      (_: nixosConfiguration: {
                        _file = ./machines.nix;
                        key = ./machines.nix;
                        imports = [ nixosConfiguration ] ++ builtins.attrValues selfNixosModules;
                        home-manager.sharedModules = selfHomeModules;
                      })
                      (
                        builtins.mapAttrs (_: { value, ... }: value) (
                          selfLib.lib.filterAttrsByKey key default config.self.nixosConfigurations
                        )
                      );
                };

                homeConfigurations = selfLib.machines.makeHomeConfigurationAttrs {
                  inherit specialArgs;
                  inherit (config.self.lib.pkgs)
                    nixpkgs
                    home-manager
                    config
                    overlays
                    ;

                  modules =
                    builtins.mapAttrs
                      (_: homeConfiguration: {
                        _file = ./machines.nix;
                        key = ./machines.nix;
                        imports = [ homeConfiguration ] ++ builtins.attrValues selfHomeModules;
                      })
                      (
                        builtins.mapAttrs (_: { value, ... }: value) (
                          selfLib.lib.filterAttrsByKey key default config.self.homeConfigurations
                        )
                      );
                };
              };
          in
          {
            self.lib = makeMachineAttrs "self";
            flake = makeMachineAttrs "flake";
          };
      };
  };
}
