{
  self,
  selfLib,
  ...
}:

{
  self.flakeModules.nixos-tests = {
    self = false;
    flake = true;
    value =
      { lib, config, ... }:
      {
        options.self.nixosTests = lib.mkOption {
          default = { };
          description = "Declarative container NixOS tests.";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                imports = [ (selfLib.lib.selfSubmodule (lib.types.functionTo lib.types.deferredModule)) ];

                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    defaultText = lib.literalMD "the attribute name";
                    description = "Test name, used in the NixOS test name.";
                  };
                };
              }
            )
          );
        };

        config = {
          self.lib.nixosTests =
            lib.genAttrs (builtins.filter (system: lib.hasSuffix "linux" system) config.systems)
              (
                system:
                builtins.mapAttrs (
                  _: nixosTest:
                  (config.self.lib.${system}.pkgs.extend self.overlays.nixos-tests)
                  .${selfLib.overlays.namespace}.makeNixosTest
                    (selfLib.lib.filterAttrsByKey "self" true nixosTest)
                ) config.self.nixosTests
              );

          perSystem =
            { pkgs, ... }:
            lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
              checks = lib.mapAttrs' (
                name: nixosTest:
                lib.nameValuePair "nixos-test-${name}" (
                  (pkgs.extend self.overlays.nixos-tests).${selfLib.overlays.namespace}.makeNixosTest (
                    selfLib.lib.filterAttrsByKey "self" true nixosTest
                  )
                )
              ) (selfLib.lib.filterAttrsByKey "flake" false config.self.nixosTests);
            };
        };
      };
  };
}
