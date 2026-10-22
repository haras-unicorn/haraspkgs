{ selfLib, ... }:

{
  self.devModules.shell = {
    self = false;
    flake = true;
    value =
      {
        config,
        lib,
        ...
      }:
      let
        bwrapFileType = lib.types.submodule {
          options = {
            mode = lib.mkOption {
              type = lib.types.enum [
                "ro"
                "rw"
              ];
              default = "ro";
              description = "Bind mode.";
            };

            source = lib.mkOption {
              type = lib.types.nullOr (lib.types.either lib.types.path lib.types.package);
              default = null;
              description = "Store path or derivation bound at the destination.";
            };

            text = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
              description = "Text written to the store and bound at the destination.";
            };
          };
        };

        globalBwrapOverlay = _final: prev: {
          ${selfLib.overlays.namespace} = (prev.${selfLib.overlays.namespace} or { }) // {
            makeBubblewrapWrapper =
              args:
              let
                makeBubblewrapWrapper =
                  (prev.${selfLib.overlays.namespace} or { }).makeBubblewrapWrapper
                    or (throw "makeBubblewrapWrapper is missing; make sure self.overlays.shell is in nixpkgs.overlays");
              in
              makeBubblewrapWrapper (
                args
                // {
                  files = config.bwrap.files // (args.files or { });
                }
              );
          };
        };
      in
      {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "haraspkgs-dev-shell";
            description = "Derivation name used for the shell.";
          };

          packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Packages added to the shell.";
          };

          buildInputs = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Build inputs added to the shell.";
          };

          nativeBuildInputs = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Native build inputs added to the shell.";
          };

          inputsFrom = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Derivations whose build inputs are inherited.";
          };

          shellHook = lib.mkOption {
            type = selfLib.dev.commands;
            default = [ ];
            description = "Commands run when the shell starts.";
          };

          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.envVar;
            default = { };
            description = "Environment variables exported by the shell.";
          };

          passthru = lib.mkOption {
            type = lib.types.mkOptionType {
              name = "attrs";
              description = "nested attribute set";
              descriptionClass = "noun";
              check = value: lib.isAttrs value;
              merge = loc: defs: lib.foldl' lib.recursiveUpdate { } (builtins.map (def: def.value) defs);
            };
            default = { };
            description = "Derivation passthru attrs.";
          };

          bwrap.files = lib.mkOption {
            type = lib.types.attrsOf bwrapFileType;
            default = { };
            description = "Files bound into every bwrap wrapper in this shell.";
          };
        };

        config = {
          nixpkgs.overlays = lib.mkAfter [ globalBwrapOverlay ];
        };
      };
  };
}
