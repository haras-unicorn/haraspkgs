{ selfLib, ... }:

{
  self.flakeModules.unit-tests = {
    self = false;
    flake = true;
    value =
      {
        lib,
        config,
        inputs,
        self,
        flake-parts-lib,
        ...
      }:
      let
        suite = lib.types.lazyAttrsOf lib.types.raw;

        nixUnit = if inputs ? nix-unit then inputs.nix-unit else selfLib.lib.inputs.nix-unit;

        # nix-unit evaluates in a sandbox without network, so the transitive
        # inputs of every input must be overridden too, keyed by input path
        # (`<input>/<nested>/...`).
        unitInputs = selfLib.flattenInputs (
          builtins.removeAttrs inputs [ "self" ]
          // {
            nix-unit = nixUnit;
          }
        );
      in
      {
        imports = [
          nixUnit.modules.flake.default
          {
            config = {
              flake.tests = config.self.unitTests;

              perSystem =
                { config, ... }:
                {
                  nix-unit.tests = config.self.unitTests;
                  nix-unit.inputs = unitInputs;
                };
            };
          }
        ];

        options = {
          self.unitTests = lib.mkOption {
            type = suite;
            default = { };
            description = "System-agnostic unit test suites.";
          };

          perSystem = flake-parts-lib.mkPerSystemOption (
            { ... }:
            {
              options.self.unitTests = lib.mkOption {
                type = suite;
                default = { };
                description = "Per-system unit test suites.";
              };
            }
          );
        };

        config = {
          self.lib.unitTests = config.self.unitTests;
        };
      };
  };
}
