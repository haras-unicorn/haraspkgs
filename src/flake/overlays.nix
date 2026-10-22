{ selfLib, ... }:

{
  self.flakeModules.overlays = {
    self = false;
    flake = true;
    value =
      {
        lib,
        config,
        ...
      }:
      {
        options.self.overlays = {
          namespace = lib.mkOption {
            type = lib.types.str;
            default = "selfPackages";
            description = "Namespace under which to put overlays.";
          };

          overlays = lib.mkOption {
            default = { };
            description = "Overlays to namespace and make packages and apps out of.";
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, ... }:
                {
                  imports = [
                    (selfLib.lib.selfSubmodule (lib.types.functionTo (lib.types.functionTo lib.types.attrs)))
                  ];

                  options = {
                    name = lib.mkOption {
                      type = lib.types.str;
                      default = name;
                      description = "Overlay name.";
                    };

                    deps = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = "Overlay dependencies, as exact names or slash-delimited regexes.";
                    };
                  };
                }
              )
            );
          };
        };

        config =
          let
            cfg = config.self.overlays;
          in
          {
            self.assertions = [ (selfLib.overlays.makeUndefinedDepsAssertion cfg.overlays) ];

            self.lib = {
              overlays = {
                namespace = cfg.namespace;
                overlays = selfLib.overlays.makeOverlayAttrs cfg.namespace cfg.overlays (
                  selfLib.lib.filterAttrsByKey "self" true
                );
                nixpkgs = config.self.lib.overlays.overlays.default;
              };
            }
            // lib.genAttrs config.systems (system: {
              overlays = selfLib.overlays.makeOverlayResult config.self.lib.pkgs.${system} cfg.namespace [
                config.self.lib.overlays.overlays.default
              ];
            });

            flake.overlays = selfLib.overlays.makeOverlayAttrs cfg.namespace cfg.overlays (
              selfLib.lib.filterAttrsByKey "flake" false
            );

            perSystem =
              { pkgs, ... }:
              {
                inherit (selfLib.overlays.makeOverlayResult pkgs cfg.namespace [ config.flake.overlays.default ])
                  packages
                  apps
                  ;
              };
          };
      };
  };
}
