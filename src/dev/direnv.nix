{ selfLib, ... }:

{
  self.devModules.direnv = {
    self = false;
    flake = true;
    value =
      {
        config,
        lib,
        options,
        self,
        modulePaths,
        ...
      }:
      let
        direnv = config.direnv;

        modulePathsInRepository = selfLib.dev.repositoryPaths self.outPath modulePaths;

        watchLines =
          builtins.map (path: "watch_file ${lib.escapeShellArg path}") direnv.watch.files
          ++ builtins.map (path: "watch_dir ${lib.escapeShellArg path}") direnv.watch.dirs;

        # The watches come after `use flake` on purpose: direnv records their
        # modification times (in whole seconds) when they are registered, and the
        # shell hook run by `use flake` can modify watched directories. Recording
        # before it would make every such load look like a change and reload
        # forever.
        envrcText = lib.concatStringsSep "\n" (
          lib.optional (direnv.extra != "") direnv.extra
          ++ [ "use flake ${lib.escapeShellArgs direnv.useFlake}" ]
          ++ watchLines
        );
      in
      {
        options.direnv = {
          enable = lib.mkEnableOption "generated .envrc";

          watch = {
            files = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = modulePathsInRepository.files;
              defaultText = lib.literalMD "the files passed to `makeFlake` as `modules`, relative to the repository root";
              description = "Files whose changes reload the shell, relative to the repository root.";
            };

            dirs = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = modulePathsInRepository.dirs;
              defaultText = lib.literalMD "the directories passed to `makeFlake` as `modules`, relative to the repository root";
              description = "Directories watched recursively; any change inside reloads the shell.";
            };
          };

          useFlake = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "."
              "--show-trace"
            ];
            description = "Arguments passed to `use flake`.";
          };

          extra = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Lines added to `.envrc` before `use flake`.";
          };
        };

        config = lib.mkIf direnv.enable (
          lib.mkMerge [
            {
              file.".envrc" = {
                text = envrcText;
                format = false;
              };
            }
            (lib.optionalAttrs (options ? git) {
              git.ignore.patterns = "/.direnv";
            })
          ]
        );
      };
  };
}
