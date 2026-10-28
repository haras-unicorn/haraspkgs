{ selfLib, config, ... }:

let
  haraspkgsModules = builtins.attrValues (
    builtins.mapAttrs (_: { value, ... }: value) (
      selfLib.lib.filterAttrsRecursiveByKey "flake" false config.self.devModules
    )
  );
in
{
  self.flakeModules.dev = {
    self = false;
    flake = true;
    value =
      {
        lib,
        config,
        self,
        inputs,
        specialArgs,
        ...
      }:
      {
        options = {
          self.devModules = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule (selfLib.lib.selfSubmodule lib.types.deferredModule));
            default = { };
            description = "Development shell modules.";
          };

          self.devShells = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule (selfLib.lib.selfSubmodule lib.types.deferredModule));
            default = { };
            description = "Named development shells.";
          };

          flake.devModules = lib.mkOption {
            type = lib.types.attrsOf lib.types.deferredModule;
            default.default = { };
            description = "Flake development shell modules.";
          };
        };

        config =
          let
            makeDevShellAttrs =
              pkgs: devShells:
              (pkgs.extend selfLib.overlays.overlays.dev).${selfLib.overlays.namespace}.evaluateDevShellAttrs (
                specialArgs
                // {
                  inherit self inputs;
                }
              ) ([ config.self.lib.devModules.default ] ++ haraspkgsModules) devShells;
          in
          {
            self.lib = {
              devModules = selfLib.lib.makeModuleAttrs (
                selfLib.lib.filterAttrsByKey "self" true config.self.devModules
              );
            }
            // lib.genAttrs config.systems (system: {
              devShells = makeDevShellAttrs config.self.lib.pkgs.${system} (
                builtins.mapAttrs (_: { value, ... }: value) (
                  selfLib.lib.filterAttrsByKey "self" true config.self.devShells
                )
              );
            });

            flake.devModules = selfLib.lib.makeModuleAttrs (
              selfLib.lib.filterAttrsByKey "flake" false config.self.devModules
            );

            perSystem =
              {
                lib,
                pkgs,
                system,
                ...
              }:
              {
                devShells = makeDevShellAttrs pkgs (
                  builtins.mapAttrs (_: { value, ... }: value) (
                    selfLib.lib.filterAttrsByKey "flake" false config.self.devShells
                  )
                );

                checks =
                  selfLib.dev.extractPassthruDevShellAttrs config.flake.devShells.${system} "checks"
                    lib.isDerivation;

                packages =
                  selfLib.dev.extractPassthruDevShellAttrs config.flake.devShells.${system} "packages"
                    lib.isDerivation;

                apps = selfLib.dev.extractPassthruDevShellAttrs config.flake.devShells.${system} "apps" (
                  value:
                  value ? type
                  && value.type == "app"
                  && value ? program
                  && (builtins.isString value.program || builtins.isPath value.program)
                );

                formatter = lib.mkIf (
                  config.flake.devShells.${system} ? default
                  && config.flake.devShells.${system}.default.passthru ? formatter
                ) config.flake.devShells.${system}.default.passthru.formatter;
              };
          };
      };
  };
}
