{ selfLib, ... }:

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
      let
        devModuleArgs = specialArgs // {
          inherit self inputs;
        };
      in
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

        config = {
          self.lib = {
            devModules = selfLib.lib.makeModuleAttrs (
              selfLib.lib.filterAttrsByKey "self" true config.self.devModules
            );
          }
          // lib.genAttrs config.systems (system: {
            devShells =
              (config.self.lib.pkgs.${system}.extend self.overlays.dev)
              .${selfLib.overlays.namespace}.evaluateDevShellAttrs
                devModuleArgs
                (builtins.mapAttrs (_: { value, ... }: value) (
                  selfLib.lib.filterAttrsByKey "self" true config.self.devShells
                ))
                [ config.self.lib.devModules.default ];
          });

          flake.devModules = selfLib.lib.makeModuleAttrs (
            selfLib.lib.filterAttrsByKey "flake" false config.self.devModules
          );

          perSystem =
            { lib, system, ... }:
            let
              devShells = config.flake.devShells.${system};
              selfDevShells = config.self.lib.${system}.devShells;
            in
            {
              checks = selfLib.dev.extractPassthruDevShellAttrs devShells "checks" lib.isDerivation;

              packages = selfLib.dev.extractPassthruDevShellAttrs devShells "packages" lib.isDerivation;

              apps = selfLib.dev.extractPassthruDevShellAttrs devShells "apps" (
                value:
                value ? type
                && value.type == "app"
                && value ? program
                && (builtins.isString value.program || builtins.isPath value.program)
              );

              devShells =
                (config.self.lib.${system}.pkgs.extend self.overlays.dev)
                .${selfLib.overlays.namespace}.evaluateDevShellAttrs
                  devModuleArgs
                  (builtins.mapAttrs (_: { value, ... }: value) (
                    selfLib.lib.filterAttrsByKey "flake" false config.self.devShells
                  ))
                  [ config.self.lib.devModules.default ];
            }
            // lib.optionalAttrs (selfDevShells ? default && selfDevShells.default.passthru ? formatter) {
              formatter = selfDevShells.default.passthru.formatter;
            };
        };
      };
  };
}
