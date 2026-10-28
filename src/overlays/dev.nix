{ selfLib, ... }:

{
  self.overlays.overlays.dev = {
    flake = true;
    value =
      final: prev:
      let
        evaluateDevShellAttrs =
          specialArgs: devModules: devShells:
          builtins.mapAttrs (
            _: shell:
            let
              shellPkgs = final.extend selfLib.overlays.overlays.shell;

              pkgsModule = { lib, config, ... }: {
                options = {
                  nixpkgs = {
                    system = lib.mkOption {
                      type = lib.types.str;
                      default = shellPkgs.stdenv.hostPlatform.system;
                      description = "System used to recreate the shell package set.";
                    };

                    config = lib.mkOption {
                      type = lib.types.attrsOf lib.types.raw;
                      default = { };
                      description = "Nixpkgs configuration used to recreate the shell package set.";
                    };

                    overlays = lib.mkOption {
                      type = lib.types.listOf (lib.types.functionTo (lib.types.functionTo lib.types.raw));
                      default = [ ];
                      description = "Overlays used to recreate the shell package set.";
                    };
                  };
                };

                config = {
                  _module.args.pkgs = import shellPkgs.path {
                    inherit (config.nixpkgs) system config overlays;
                  };

                  nixpkgs.config = shellPkgs.config;

                  nixpkgs.overlays = lib.mkMerge [
                    (lib.mkBefore shellPkgs.overlays)
                  ];
                };
              };

              config =
                (shellPkgs.lib.evalModules {
                  inherit specialArgs;
                  modules = [
                    pkgsModule
                    shell
                  ]
                  ++ devModules;
                }).config;

              pkgs = import shellPkgs.path {
                inherit (config.nixpkgs) system config overlays;
              };
            in
            pkgs.mkShell {
              inherit (config)
                name
                packages
                buildInputs
                nativeBuildInputs
                inputsFrom
                env
                passthru
                ;
              shellHook = selfLib.dev.concatCommands config.shellHook;
            }
          ) devShells;
      in
      {
        inherit evaluateDevShellAttrs;

        makeDevTest =
          {
            name,
            value,
            moduleArgs,
            devModules,
            source,
            ...
          }:
          let
            shell =
              (evaluateDevShellAttrs moduleArgs devModules {
                test = {
                  imports = value.modules;
                };
              }).test;
          in
          shell.overrideAttrs (prev: {
            name = "dev-test-${name}";
            phases = [ "buildPhase" ];
            buildPhase = ''
              cp -r ${source} source
              chmod -R u+w source
              cd source
              ${prev.shellHook or ""}
              ${selfLib.dev.concatCommands value.commands}
              mkdir -p $out
            '';
          });
      };
  };
}
