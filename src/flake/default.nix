{ config, lib, ... }:

# IMPORTANT: this file is an infinite recursion landmine
# please do not edit unless you are 100% sure of what you are doing

let
  selfLib = config.self.lib;

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
          type = lib.types.mkOptionType {
            name = "recursiveAttrs";
            description = "nested attribute set";
            descriptionClass = "noun";
            check = value: lib.isAttrs value;
            merge = loc: defs: lib.foldl' lib.recursiveUpdate { } (builtins.map (def: def.value) defs);
          };
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
              freeformType = lib.types.attrs;
              options = selfOptions;
            };
          }
        else
          selfOptions;

      config = {
        _module.args.selfLib = selfLib.lib.filterAttrsRecursiveByKeys [ "self" "flake" ] (
          selfLib.lib.filterAttrsRecursiveByKey "self" true config.self.lib
        );

        perSystem = { system, ... }: {
          _module.args.selfLib =
            lib.recursiveUpdate
              (selfLib.lib.filterAttrsRecursiveByKeys [ "self" "flake" ] (
                selfLib.lib.filterAttrsRecursiveByKey "self" true config.self.lib
              ))
              (
                if config.self.lib ? ${system} then
                  selfLib.lib.filterAttrsRecursiveByKeys [ "self" "flake" ] (
                    selfLib.lib.filterAttrsRecursiveByKey "self" true config.self.lib.${system}
                  )
                else
                  { }
              );
        };

        self.flakeModules.base = {
          self = false;
          flake = true;
          value = baseModule;
        };

        flake.lib =
          (selfLib.lib.filterAttrsRecursiveByKeys [ "self" "flake" ] (
            selfLib.lib.filterAttrsRecursiveByKey "flake" false config.self.lib
          ))
          // {
            selfModules = builtins.map ({ value, ... }: value) (
              builtins.attrValues (selfLib.lib.filterAttrsRecursiveByKey "self" true config.self.flakeModules)
            );
          };

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

      haraspkgsModules = builtins.attrValues (removeAttrs config.flake.flakeModules [ "default" ]);

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
  imports = [ baseModule ];

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
