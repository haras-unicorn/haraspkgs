{
  selfLib,
  ...
}:

{
  self.devModules.check = {
    self = false;
    flake = true;
    value =
      {
        config,
        lib,
        pkgs,
        self,
        ...
      }:
      let
        checks = lib.filterAttrs (_: check: check.enable) config.check.checks;

        mkCheck =
          name: check:
          pkgs.runCommand "check-${name}"
            {
              src = self.outPath;
              nativeBuildInputs = config.check.packages ++ check.packages;
            }
            ''
              cp -r $src source
              chmod -R u+w source
              cd source
              ${selfLib.dev.concatCommands check.commands}
              touch $out
            '';
      in
      {
        options.check = {
          packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Packages available to every check.";
          };

          checks = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, ... }:
                {
                  options = {
                    enable = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Whether to expose the check at `${name}`.";
                    };

                    packages = lib.mkOption {
                      type = lib.types.listOf lib.types.package;
                      default = [ ];
                      description = "Packages available to the check at `${name}`.";
                    };

                    commands = lib.mkOption {
                      type = selfLib.dev.commands;
                      default = [ ];
                      description = "Commands run by the check at `${name}`.";
                    };
                  };
                }
              )
            );
            default = { };
            description = "Checks to expose through `perSystem.checks`.";
          };
        };

        config = lib.mkMerge [
          {
            passthru.checks = builtins.mapAttrs mkCheck checks;
          }
          (lib.mkIf (checks != { }) {
            cli.commands.check = {
              description = "Run all enabled checks in the checkout.";
              packages =
                config.check.packages
                ++ lib.flatten (builtins.map (check: check.packages) (builtins.attrValues checks));
              commands = builtins.map (name: {
                header = "check ${name}";
                text = selfLib.dev.concatCommands checks.${name}.commands;
              }) (builtins.filter (name: checks.${name}.commands != [ ]) (builtins.attrNames checks));
            };
          })
        ];
      };
  };
}
