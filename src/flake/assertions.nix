{
  self.flakeModules.assertions = {
    self = false;
    flake = true;
    value = { lib, config, ... }: {
      options.self = {
        assertions = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                assertion = lib.mkOption {
                  type = lib.types.bool;
                  description = "What to assert.";
                };
                message = lib.mkOption {
                  type = lib.types.str;
                  description = "What error message to show";
                };
              };
            }
          );
        };
      };

      config.self.lib.asserted =
        assert lib.assertMsg (builtins.all ({ assertion, ... }: assertion) config.self.assertions) ''
          Flake assertions failed:
          ${builtins.concatStringsSep "\n\n" (
            builtins.map ({ message, ... }: message) config.self.assertions
          )}
        '';
        true;
    };
  };
}
