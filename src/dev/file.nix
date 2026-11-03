{
  self.devModules.file = {
    self = false;
    flake = true;
    value =
      {
        lib,
        config,
        options,
        pkgs,
        ...
      }:
      let
        files = builtins.map ({ name, value }: value // { path = name; }) (lib.attrsToList config.file);

        enabledFiles = builtins.filter (file: file.enable) files;

        textFiles = builtins.filter (file: file.text != null || file.ensure != null) enabledFiles;

        sourceFiles = builtins.filter (file: file.source != null) enabledFiles;

        fileText = text: (lib.trim text) + "\n";

        formatCommand = lib.attrByPath [ "format" "command" ] null config;

        formatBinary = lib.optionalString (formatCommand != null) "${formatCommand}/bin/format";

        formatterFor = file: if file.format then formatBinary else "";

        unformattedPaths = builtins.map (file: file.path) (builtins.filter (file: !file.format) textFiles);

        writeFunctions = ''
          __haraspkgs_write_file() {
            local path="$1" content="$2" executable="$3" formatter="$4"
            local desired="$content"

            if [ -n "$formatter" ]; then
              desired="$(printf '%s' "$content" | "$formatter" --quiet --stdin "$path" && printf x)"
              if [ "''${desired: -1}" != x ]; then
                printf "format failed %s\n" "$path" >&2
                return 1
              fi
              desired="''${desired%x}"
            fi

            mkdir -p "$(dirname -- "$path")"
            if [ -L "$path" ]; then
              rm -f -- "$path"
            fi
            if ! printf '%s' "$desired" | cmp -s - "$path"; then
              printf '%s' "$desired" > "$path"
              printf "write %s\n" "$path" >&2
            fi

            if [ -n "$executable" ]; then
              if [ ! -x "$path" ]; then chmod +x "$path"; fi
            elif [ -x "$path" ]; then
              chmod -x "$path"
            fi
          }

          __haraspkgs_ensure_file() {
            if [ ! -f "$1" ]; then
              __haraspkgs_write_file "$@"
            fi
          }
        '';

        writeCalls = builtins.concatStringsSep "\n" (
          builtins.map (
            file:
            builtins.concatStringsSep " " [
              (if file.text != null then "__haraspkgs_write_file" else "__haraspkgs_ensure_file")
              (lib.escapeShellArg file.path)
              (lib.escapeShellArg (fileText (if file.text != null then file.text else file.ensure)))
              (lib.escapeShellArg (lib.optionalString file.executable "1"))
              (lib.escapeShellArg (formatterFor file))
            ]
          ) textFiles
        );

        linkFunction = ''
          __haraspkgs_link_file() {
            local path="$1" target="$2"

            mkdir -p "$(dirname -- "$path")"
            if [ "$(readlink -- "$path" || true)" != "$target" ]; then
              ln -sfn -- "$target" "$path"
              printf "link %s\n" "$path" >&2
            fi
          }
        '';

        linkFiles = builtins.map (
          file:
          let
            name = builtins.baseNameOf (toString file.source);
            destination = "/lib/${name}";
            package = pkgs.writeTextFile {
              inherit name;
              inherit destination;
              executable = file.executable;
              text = fileText (builtins.readFile file.source);
            };
          in
          file
          // {
            inherit package;
            source = "${package}${destination}";
          }
        ) sourceFiles;

        linkCalls = builtins.concatStringsSep "\n" (
          builtins.map (
            file:
            builtins.concatStringsSep " " [
              "__haraspkgs_link_file"
              (lib.escapeShellArg file.path)
              (lib.escapeShellArg file.source)
            ]
          ) linkFiles
        );

        ignoreText = builtins.concatStringsSep "\n" (
          lib.sortOn lib.id (
            builtins.map (file: "/${file.path}") (
              builtins.filter (file: file.path != ".gitignore" && file.enable && file.ignore) files
            )
          )
        );
      in
      {
        options.file = lib.mkOption {
          default = { };
          description = "Files to generate in the repository when entering the shell.";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { config, name, ... }:
              {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = config.text != null || config.source != null || config.ensure != null;
                    defaultText = lib.literalExpression ''
                      config.text != null || config.source != null || config.ensure != null
                    '';
                    description = "Whether to generate the file at `${name}`.";
                  };

                  text = lib.mkOption {
                    type = lib.types.nullOr lib.types.lines;
                    default = null;
                    description = "File text that will be written to `${name}`.";
                  };

                  ensure = lib.mkOption {
                    type = lib.types.nullOr lib.types.lines;
                    default = null;
                    description = "File text that is written only if `${name}` does not exist.";
                  };

                  source = lib.mkOption {
                    type = lib.types.nullOr lib.types.path;
                    default = null;
                    description = "Source file that will be linked to `${name}`.";
                  };

                  format = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Format the generated text before writing it. When false, the exact text is written and `dev format` leaves the file alone.";
                  };

                  executable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = "Whether to make the generated or linked file executable.";
                  };

                  ignore = lib.mkOption {
                    type = lib.types.bool;
                    default = config.source != null;
                    defaultText = lib.literalExpression "config.source != null";
                    description = "Whether to add the file to the generated .gitignore.";
                  };
                };
              }
            )
          );
        };

        config = lib.mkMerge [
          {
            file.".gitignore".text = lib.mkIf (ignoreText != "") (lib.mkBefore ignoreText);

            packages = builtins.map ({ package, ... }: package) linkFiles;

            shellHook = lib.mkBefore (
              lib.optional (linkCalls != "") {
                header = "linking";
                text = ''
                  ${linkFunction}
                  ${linkCalls}
                  unset -f __haraspkgs_link_file
                '';
              }
              ++ lib.optional (writeCalls != "") {
                header = "writing";
                text = ''
                  ${writeFunctions}
                  ${writeCalls}
                  unset -f __haraspkgs_write_file __haraspkgs_ensure_file
                '';
              }
            );
          }
          (lib.optionalAttrs (options ? format) {
            format.excludes = unformattedPaths;
          })
        ];
      };
  };
}
