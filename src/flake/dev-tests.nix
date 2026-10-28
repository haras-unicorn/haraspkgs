{ selfLib, config, ... }:

let
  haraspkgsModules = builtins.attrValues (
    builtins.mapAttrs (_: { value, ... }: value) (
      selfLib.lib.filterAttrsRecursiveByKey "flake" false config.self.devModules
    )
  );
in
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
          pkgs: name: devTest:
          (pkgs.extend selfLib.overlays.overlays.dev).${selfLib.overlays.namespace}.makeDevTest {
            inherit name;
            inherit (devTest) value;
            moduleArgs = devModuleArgs;
            devModules = [ config.self.lib.devModules.default ] ++ haraspkgsModules;
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
          self.lib = lib.genAttrs config.systems (system: {
            devTests = builtins.mapAttrs (
              name: devTest: makeDevTest config.self.lib.pkgs.${system} name devTest
            ) (selfLib.lib.filterAttrsByKey "self" true config.self.devTests);
          });

          perSystem =
            { pkgs, ... }:
            {
              checks = lib.mapAttrs' (
                name: devTest: lib.nameValuePair "dev-test-${name}" (makeDevTest pkgs name devTest)
              ) (selfLib.lib.filterAttrsByKey "flake" false config.self.devTests);
            };
        };
      };
  };
}
