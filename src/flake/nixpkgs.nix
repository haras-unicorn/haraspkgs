{ selfLib, ... }:

{
  self.flakeModules.nixpkgs = {
    self = false;
    flake = true;
    value =
      {
        lib,
        inputs,
        config,
        ...
      }:
      {
        options.self.nixpkgs = {
          config = lib.mkOption {
            type = selfLib.lib.recursiveAttrsType;
            default = { };
            description = "Extra nixpkgs configuration.";
          };

          overlays = lib.mkOption {
            type = lib.types.listOf (lib.types.functionTo (lib.types.functionTo lib.types.raw));
            default = [ ];
            description = "Overlays applied to pkgs.";
          };
        };

        config =
          let
            cfg = config.self.nixpkgs;
          in
          {
            self.lib = {
              pkgs = {
                nixpkgs = if inputs ? nixpkgs then inputs.nixpkgs else selfLib.lib.inputs.nixpkgs;
                home-manager =
                  if inputs ? home-manager then inputs.home-manager else selfLib.lib.inputs.home-manager;
                config = selfLib.nixpkgs.makeConfig cfg.config;
                overlays = [
                  config.self.lib.overlays.nixpkgs
                ]
                ++ cfg.overlays
                ++ (selfLib.nixpkgs.makeExtraOverlays cfg.config);

                makePkgs =
                  let
                    nixpkgs = config.self.lib.pkgs.nixpkgs;
                    nixpkgsConfig = config.self.lib.pkgs.config;
                    nixpkgsOverlays = config.self.lib.pkgs.overlays;
                  in
                  {
                    system,
                    config ? { },
                    overlays ? [ ],
                    ...
                  }@attrs:
                  let
                    args = builtins.removeAttrs attrs [
                      "system"
                      "config"
                      "overlays"
                    ];
                  in
                  import nixpkgs (
                    args
                    // {
                      inherit system;
                      config = lib.recursiveUpdate nixpkgsConfig config;
                      overlays = nixpkgsOverlays ++ overlays;
                    }
                  );
              }
              # NOTE: when infinite recursion strikes on the other one
              # even though the other one is the convention
              // lib.genAttrs config.systems (system: config.self.lib.pkgs.makePkgs { inherit system; });
            }
            // lib.genAttrs config.systems (system: {
              pkgs = config.self.lib.pkgs.makePkgs { inherit system; };
            });

            perSystem =
              { system, ... }:
              {
                _module.args.pkgs = config.self.lib.pkgs.makePkgs { inherit system; };
              };
          };
      };
  };
}
