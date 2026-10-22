{
  selfLib,
  ...
}:

{
  self.flakeModules.dev-tests = {
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

        makeDevTest =
          system: name: devTest:
          (config.self.lib.${system}.pkgs.extend self.overlays.dev).${selfLib.overlays.namespace}.makeDevTest
            {
              inherit name;
              inherit (devTest) value;
              moduleArgs = devModuleArgs;
              devModules = [ config.self.lib.devModules.default ];
              source = self.outPath;
            };
      in
      {
        options.self.devTests = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { ... }:
              {
                imports = [
                  (selfLib.lib.selfSubmodule (
                    lib.types.submodule (
                      { ... }:
                      {
                        options = {
                          modules = lib.mkOption {
                            type = lib.types.listOf lib.types.deferredModule;
                            default = [ ];
                            description = "Dev modules to test.";
                          };

                          commands = lib.mkOption {
                            type = selfLib.dev.commands;
                            default = [ ];
                            description = "Commands run after the shell hook.";
                          };
                        };
                      }
                    )
                  ))
                ];
              }
            )
          );
          default = { };
          description = "Dev shell module tests.";
        };

        config = {
          self.lib.devTests = lib.genAttrs config.systems (
            system:
            builtins.mapAttrs (name: devTest: makeDevTest system name devTest) (
              selfLib.lib.filterAttrsByKey "self" true config.self.devTests
            )
          );

          perSystem =
            { system, ... }:
            {
              checks = lib.mapAttrs' (
                name: devTest: lib.nameValuePair "dev-test-${name}" (makeDevTest system name devTest)
              ) (selfLib.lib.filterAttrsByKey "flake" false config.self.devTests);
            };
        };
      };
  };
}
