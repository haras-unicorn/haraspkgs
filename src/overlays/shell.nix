{ selfLib, ... }:

{
  self.overlays.overlays.shell = {
    deps = [ "flake-root" ];
    flake = true;
    value = final: prev: {
      makeBubblewrapWrapper =
        {
          name ? "${prev.lib.getName package}-wrapped",
          package,
          arguments ? [ ],
          env ? { },
          stdin ? null,
          files ? { },
          runtimeInputs ? [ ],
          network ? false,
          bwrapArgs ? [ ],
        }:
        let
          lib = prev.lib;

          flakeRoot = final.harasPackages.flake-root;

          quote = lib.escapeShellArg;

          rootPath = "\"$root\"";
          homePath = "\"$HOME\"";

          normalizeFile =
            file:
            if !(builtins.isAttrs file.value) then
              throw "makeBubblewrapWrapper files.${file.name} must be an attrset with mode, source, and text"
            else
              let
                mode = file.value.mode or "ro";
                source = file.value.source or null;
                text = file.value.text or null;
                home = lib.hasPrefix "~/" file.name;
                relative = if home then lib.removePrefix "~/" file.name else file.name;
              in
              if source != null && text != null then
                throw "makeBubblewrapWrapper files.${file.name}: source and text are mutually exclusive"
              else if mode != "ro" && mode != "rw" then
                throw "makeBubblewrapWrapper files.${file.name}: mode must be \"ro\" or \"rw\""
              else if mode == "rw" && (source != null || text != null) then
                throw "makeBubblewrapWrapper files.${file.name}: mode \"rw\" cannot use source or text"
              else
                {
                  inherit (file) name;
                  inherit
                    mode
                    source
                    text
                    home
                    relative
                    ;
                };

          normalizedFiles = builtins.map normalizeFile (lib.attrsToList files);

          providedFiles = builtins.filter (file: file.source != null || file.text != null) normalizedFiles;

          boundFiles = builtins.filter (file: file.source == null && file.text == null) normalizedFiles;

          repoProvidedFiles = builtins.filter (file: !file.home) providedFiles;

          repoBoundFiles = builtins.filter (file: !file.home) boundFiles;

          homeFiles = builtins.filter (file: file.home) normalizedFiles;

          hasRepoProvidedFiles = repoProvidedFiles != [ ];

          destinationPath =
            file:
            if file.home then "${homePath}/${quote file.relative}" else "${rootPath}/${quote file.relative}";

          fileSource =
            file:
            if file.text != null then
              final.writeText "bwrap-${builtins.baseNameOf file.relative}" file.text
            else
              file.source;

          fileMode = mode: if mode == "rw" then "--bind" else "--ro-bind";

          bindSource =
            file: if file.source != null then quote (toString (fileSource file)) else destinationPath file;

          bindMode = file: if file.source != null then "--ro-bind" else fileMode file.mode;

          repoBoundArguments = lib.concatMap (file: [
            (quote (fileMode file.mode))
            (destinationPath file)
            (destinationPath file)
          ]) repoBoundFiles;

          homeBindArguments = lib.concatMap (file: [
            (quote (bindMode file))
            (bindSource file)
            (destinationPath file)
          ]) homeFiles;

          homePrepareLine =
            file:
            let
              directory = quote (builtins.dirOf file.relative);
              path = destinationPath file;
              source = quote (toString (fileSource file));
            in
            ''
              mkdir -p "$HOME"/${directory}
            ''
            + (
              if file.source == null && file.text == null then
                ''
                  if [ ! -e ${path} ]; then
                    mkdir -p ${path}
                  fi
                ''
              else
                ''
                  if [ ! -e ${path} ]; then
                    if [ -d ${source} ]; then
                      mkdir -p ${path}
                    else
                      touch ${path}
                    fi
                    cleanup+=(${path})
                  fi
                ''
            );

          homePrepareLines = lib.concatStringsSep "\n" (builtins.map homePrepareLine homeFiles);

          materializeLine =
            file:
            let
              directory = quote (builtins.dirOf file.relative);
              path = quote file.relative;
              base = quote (builtins.baseNameOf file.relative);
              source = quote (toString (fileSource file));
            in
            ''
              mkdir -p ${rootPath}/${directory}
              temporary=${rootPath}/.${base}.tmp.$$
              rm -rf "$temporary"
              cp -rL ${source} "$temporary"
              mv -f "$temporary" ${rootPath}/${path}
              cleanup+=("$temporary" ${rootPath}/${path})
            '';

          materializeLines = builtins.concatStringsSep "\n" (builtins.map materializeLine repoProvidedFiles);

          stageLine =
            file:
            let
              directory = quote (builtins.dirOf file.relative);
              path = quote file.relative;
              source = quote (toString (fileSource file));
            in
            ''
              mkdir -p "$stage"/${directory}
              ln -s ${source} "$stage"/${path}
            '';

          stageLines = builtins.concatStringsSep "\n" (builtins.map stageLine repoProvidedFiles);

          stageSetup = lib.optionalString hasRepoProvidedFiles ''
            cacheRoot="''${XDG_CACHE_HOME:-$HOME/.cache}/haraspkgs"
            mkdir -p "$cacheRoot"
            stage="$(mktemp -d "$cacheRoot/stage.XXXXXX")"
            workdir="$(mktemp -d "$cacheRoot/work.XXXXXX")"
            cleanup+=("$stage" "$workdir")
            ${stageLines}
          '';

          cleanupLine = ''
            cleanup=()
            cleanup_files() {
              local file
              for file in "''${cleanup[@]}"; do
                rm -rf "$file"
              done
            }
            trap cleanup_files EXIT
          '';

          baseArguments = builtins.map quote (if network then selfLib.bwrap.network else selfLib.bwrap.local);

          defaultArguments = baseArguments ++ [
            (quote "--ro-bind-try")
            (quote "/nix")
            (quote "/nix")
            (quote "--ro-bind-try")
            "\"$HOME\""
            "\"$HOME\""
            (quote "--ro-bind-try")
            (quote "/run")
            (quote "/run")
            (quote "--chdir")
            "\"$PWD\""
          ];

          rootArguments =
            if hasRepoProvidedFiles then
              [
                (quote "--overlay-src")
                "\"$stage\""
                (quote "--overlay")
                rootPath
                "\"$workdir\""
                rootPath
              ]
            else
              [
                (quote "--bind")
                rootPath
                rootPath
              ];

          environmentLines = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (key: value: "export ${key}=${quote (toString value)}") env
          );

          stdinRedirect = if stdin == null then "" else " < ${quote (toString stdin)}";

          bwrapArguments =
            defaultArguments
            ++ rootArguments
            ++ homeBindArguments
            ++ repoBoundArguments
            ++ builtins.map quote bwrapArgs;

          bwrapArgumentString = lib.concatStringsSep " " bwrapArguments;

          commandArguments = [
            (quote (lib.getExe package))
          ]
          ++ builtins.map quote arguments
          ++ [ "\"$@\"" ];

          commandArgumentString = lib.concatStringsSep " " commandArguments;

          commandWithStdin = "${commandArgumentString}${stdinRedirect}";

          runLine =
            if !prev.stdenv.isLinux then
              ''
                ${materializeLines}
                ${commandWithStdin}
              ''
            else
              ''
                if [ -n "''${NIX_BUILD_TOP:-}" ] || [ -n "''${HARASPKGS_MATERIALIZE:-}" ]; then
                  ${materializeLines}
                  ${commandWithStdin}
                else
                  ${stageSetup}
                  ${homePrepareLines}
                  bwrap \
                    ${bwrapArgumentString} \
                    ${commandWithStdin}
                fi
              '';

          runtimePackages = [
            flakeRoot
          ]
          ++ lib.optional prev.stdenv.isLinux prev.bubblewrap
          ++ runtimeInputs;
        in
        final.writeShellApplication {
          inherit name;
          runtimeInputs = runtimePackages;
          text = ''
            root="$(flake-root)"
            ${environmentLines}
            ${cleanupLine}
            ${runLine}
          '';
        };
    };
  };
}
