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

        fileWatchLines = builtins.map (path: "watch_file ${lib.escapeShellArg path}") direnv.watch.files;

        dirWatchLines = builtins.map (path: "watch_dir ${lib.escapeShellArg path}") direnv.watch.dirs;

        # The watches are registered twice. nix-direnv decides whether to
        # rebuild the cached shell during `use flake`, from the watches
        # registered earlier in that same run, because direnv clears the watches
        # of the previous load before it evaluates `.envrc`. Without the first
        # registration an edit reloads direnv and the stale cache is used.
        #
        # The second registration, after `use flake`, replaces the recorded
        # times: direnv stores them in whole seconds when a watch is registered,
        # and the shell hook run by `use flake` can modify watched directories.
        # Keeping the times from before it would make every such load look like
        # a change and reload forever.
        watchLines = fileWatchLines ++ dirWatchLines;

        envrcText = lib.concatStringsSep "\n" (
          lib.optional (direnv.extra != "") direnv.extra
          ++ watchLines
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
