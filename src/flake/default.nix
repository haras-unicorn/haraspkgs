{ config, lib, ... }:

# IMPORTANT: this file is an infinite recursion landmine
# please do not edit unless you are 100% sure of what you are doing

let
  selfLib = config.self.lib;

  haraspkgsModules = builtins.attrValues (
    builtins.mapAttrs (_: { value, ... }: value) (
      selfLib.lib.filterAttrsRecursiveByKey "flake" false config.self.flakeModules
    )
  );

  recursiveAttrsType = lib.types.mkOptionType {
    name = "recursiveAttrs";
    description = "nested attribute set";
    descriptionClass = "noun";
    check = value: lib.isAttrs value;
    merge = loc: defs: lib.foldl' lib.recursiveUpdate { } (builtins.map (def: def.value) defs);
  };

  baseModule =
    {
      lib,
      config,
      __haraspkgsSelfFreeformType,
      ...
    }:
    let
      selfOptions = {
        lib = lib.mkOption {
          type = recursiveAttrsType;
          default = { };
          description = "Library values to use in this flake or export to the flake library.";
        };

        flakeModules = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule (selfLib.lib.selfSubmodule lib.types.deferredModule));
          default.default = {
            value = { };
          };
          description = "Flake modules to use in this flake or export to the flake.";
        };

        overlays = {
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
      };
    in
    {
      _file = ./default.nix;
      key = "${./default.nix}:baseModule";

      options.self =
        if __haraspkgsSelfFreeformType then
          lib.mkOption {
            description = "Freeform self.";
            default = { };
            type = lib.types.submodule {
              freeformType = recursiveAttrsType;
              options = selfOptions;
            };
          }
        else
          selfOptions;

      config =
        let
          overlays = config.self.overlays;
        in
        {
          self.assertions = [ (selfLib.overlays.makeUndefinedDepsAssertion overlays.overlays) ];

          self.flakeModules.base = {
            self = false;
            flake = true;
            value = baseModule;
          };

          self.lib = {
            overlays = {
              namespace = overlays.namespace;
              overlays = selfLib.overlays.makeOverlayAttrs overlays.namespace overlays.overlays (
                selfLib.lib.filterAttrsByKey "self" true
              );
              nixpkgs = config.self.lib.overlays.overlays.default;
            };
          }
          // lib.genAttrs config.systems (system: {
            overlays = selfLib.overlays.makeOverlayResult config.self.lib.pkgs.${system} overlays.namespace [
              config.self.lib.overlays.overlays.default
            ];
          });

          flake.lib = {
            selfModules = builtins.map ({ value, ... }: value) (
              builtins.attrValues (selfLib.lib.filterAttrsRecursiveByKey "self" true config.self.flakeModules)
            );
          }
          // (selfLib.lib.filterAttrsRecursiveByKeys [ "self" "flake" ] (
            selfLib.lib.filterAttrsRecursiveByKey "flake" false config.self.lib
          ));

          flake.flakeModules =
            let
              exportedModules = builtins.mapAttrs (_: { value, ... }: value) (
                selfLib.lib.filterAttrsRecursiveByKey "flake" false config.self.flakeModules
              );
            in
            exportedModules
            // {
              default.imports = builtins.attrValues exportedModules;
            };

          flake.overlays = selfLib.overlays.makeOverlayAttrs overlays.namespace overlays.overlays (
            selfLib.lib.filterAttrsByKey "flake" false
          );

          _module.args.selfLib = selfLib.lib.filterAttrsRecursiveByKeys [ "self" "flake" ] (
            selfLib.lib.filterAttrsRecursiveByKey "self" true config.self.lib
          );

          perSystem = { system, pkgs, ... }: {
            _module.args.selfLib =
              lib.recursiveUpdate
                (selfLib.lib.filterAttrsRecursiveByKeys [ "self" "flake" ] (
                  selfLib.lib.filterAttrsRecursiveByKey "self" true config.self.lib
                ))
                (
                  selfLib.lib.filterAttrsRecursiveByKeys [ "self" "flake" ] (
                    selfLib.lib.filterAttrsRecursiveByKey "self" true (config.self.lib.${system} or { })
                  )
                );

            inherit
              (selfLib.overlays.makeOverlayResult pkgs overlays.namespace [ config.flake.overlays.default ])
              packages
              apps
              ;
          };
        };
    };

  makeFlake =
    {
      modules ? [ ],
      inputs,
      specialArgs ? { },
      flake-parts ? (if inputs ? flake-parts then inputs.flake-parts else selfLib.lib.inputs.flake-parts),
      import-tree ? (if inputs ? import-tree then inputs.import-tree else selfLib.lib.inputs.import-tree),
      ...
    }@attrs:
    let
      args = builtins.removeAttrs attrs [
        "modules"
        "flake-parts"
        "import-tree"
      ];

      expandModule =
        module:
        if
          builtins.isPath module && builtins.pathExists module && builtins.readFileType module == "directory"
        then
          (import-tree.addPath module).files
        else
          [ module ];

      expandedModules = builtins.concatMap expandModule (
        lib.flatten (if builtins.isList modules then modules else [ modules ])
      );

      selfModules =
        (flake-parts.lib.mkFlake
          (lib.recursiveUpdate args {
            specialArgs.__haraspkgsSelfFreeformType = true;
          })
          {
            imports = expandedModules ++ haraspkgsModules;
          }
        ).lib.selfModules;
    in
    flake-parts.lib.mkFlake
      (lib.recursiveUpdate args {
        specialArgs.__haraspkgsSelfFreeformType = false;
      })
      {
        imports = expandedModules ++ haraspkgsModules ++ selfModules;
      };
in
{
  imports = [
    baseModule
  ];

  self.lib = {
    makeFlake = selfLib.lib.selfFunctor {
      flake = true;
      functor = makeFlake;
    };
    lib = {
      inherit
        makeFlake
        baseModule
        ;
    };
  };
}
