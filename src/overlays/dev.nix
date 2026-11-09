{ selfLib, ... }:

{
  self.overlays.overlays.dev = {
    deps = [ "podman" ];
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
                      type = selfLib.lib.recursiveAttrsType;
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

            derivation = shell.overrideAttrs (prev: {
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
          in
          if value.podman.enable then
            derivation.overrideAttrs (old: {
              requiredSystemFeatures = (old.requiredSystemFeatures or [ ]) ++ [ "uid-range" ];
            })
          else
            derivation;

        makeCheck =
          {
            name,
            check,
            source,
            packages,
            ...
          }:
          let
            derivation =
              final.runCommand "check-${name}"
                {
                  src = source;
                  nativeBuildInputs = packages;
                }
                ''
                  cp -r $src source
                  chmod -R u+w source
                  cd source
                  ${selfLib.dev.concatCommands check.commands}
                  touch $out
                '';
          in
          if check.podman.enable then
            final.${selfLib.overlays.namespace}.withPodman (
              derivation.overrideAttrs (old: {
                podmanImages = (old.podmanImages or [ ]) ++ check.podman.images;
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.podman ];
              })
            )
          else
            derivation;

        makeCheckCommands =
          { checks, ... }:
          let
            podman = builtins.any ({ value, ... }: value.podman.enable) (final.lib.attrsToList checks);

            images = builtins.concatMap ({ value, ... }: value.podman.images) (final.lib.attrsToList checks);
          in
          builtins.map (name: {
            header = "check ${name}";
            text =
              if podman then
                builtins.readFile (
                  final.lib.getExe (
                    final.${selfLib.overlays.namespace}.makePodmanScript {
                      name = "check-command";
                      text = selfLib.dev.concatCommands checks.${name}.commands;
                      inherit images;
                    }
                  )
                )
              else
                selfLib.dev.concatCommands checks.${name}.commands;
          }) (builtins.filter (name: checks.${name}.commands != [ ]) (builtins.attrNames checks));
      };
  };
}
