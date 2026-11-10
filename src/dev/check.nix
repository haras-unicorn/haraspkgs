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

                    podman = {
                      enable = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = "Whether to give the check at `${name}` container support.";
                      };

                      images = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = "Images to expose in the check at `${name}`.";
                      };
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
            passthru.checks = builtins.mapAttrs (
              name: check:
              (pkgs.extend selfLib.overlays.overlays.dev).${selfLib.overlays.namespace}.makeCheck {
                inherit name check;
                source = self.outPath;
                packages = config.check.packages ++ check.packages;
              }
            ) checks;
          }
          (lib.mkIf (checks != { }) {
            cli.commands.check = {
              description = "Run all enabled checks in the checkout.";
              packages =
                config.check.packages
                ++ lib.flatten (builtins.map (check: check.packages) (builtins.attrValues checks));
              commands =
                (pkgs.extend selfLib.overlays.overlays.dev).${selfLib.overlays.namespace}.makeCheckCommands
                  {
                    inherit checks;
                  };
            };
          })
        ];
      };
  };
}
