{ selfLib, ... }:

{
  self.flakeModules.containers = {
    self = false;
    flake = true;
    value =
      {
        specialArgs,
        config,
        lib,
        ...
      }:
      {
        options.self.containers = lib.mkOption {
          default = { };
          description = "Live systemd-nspawn container configurations.";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                imports = [ (selfLib.lib.selfSubmodule (lib.types.functionTo lib.types.deferredModule)) ];

                options = {
                  name = lib.mkOption {
                    type = lib.types.strMatching "[a-z0-9][a-z0-9-]*";
                    default = name;
                    defaultText = lib.literalMD "the attribute name";
                    description = "Container name, used for the container and state directory.";
                  };
                };
              }
            )
          );
        };

        config = {
          self.lib.containers =
            lib.genAttrs (builtins.filter (system: lib.hasSuffix "linux" system) config.systems)
              (
                system:
                builtins.mapAttrs (
                  _: container: args:
                  (config.self.lib.${system}.pkgs.extend selfLib.overlays.overlays.containers)
                  .${selfLib.overlays.namespace}.makeContainer
                    (
                      container
                      // {
                        inherit args specialArgs;
                      }
                    )
                ) config.self.containers
              );
        };
      };
  };
}
