{ selfLib, ... }:

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

        partialKinds = [
          "text"
          "json"
          "toml"
          "yaml"
        ];

        partialKind = file: builtins.head (builtins.attrNames file.partial);

        validatePartial =
          file:
          lib.assertMsg (
            file.partial == null || ((file.text != null) != (file.source != null) && file.ensure == null)
          ) ''file."${file.path}".partial needs exactly one of text and source, and no ensure'';

        enabledFiles = builtins.map (
          file:
          assert validatePartial file;
          file
        ) (builtins.filter (file: file.enable) files);

        textFiles = builtins.filter (
          file: file.text != null || file.ensure != null || file.partial != null
        ) enabledFiles;

        sourceFiles = builtins.filter (file: file.source != null && file.partial == null) enabledFiles;

        partialFiles = builtins.filter (file: file.partial != null) enabledFiles;

        needsYq = builtins.any (file: partialKind file != "text") partialFiles;

        fileContent =
          file:
          if file.text != null then
            file.text
          else if file.ensure != null then
            file.ensure
          else
            builtins.readFile file.source;

        fileText = text: (lib.trim text) + "\n";

        formatCommand = lib.attrByPath [ "format" "command" ] null config;

        formatBinary = lib.optionalString (formatCommand != null) "${formatCommand}/bin/format";

        formatterFor = file: if file.format then formatBinary else "";

        unformattedPaths = builtins.map (file: file.path) (builtins.filter (file: !file.format) textFiles);

        mergeFunction = ''
          __haraspkgs_merge_partial() {
            local path="$1" content="$2" kind="$3" current needle

            if [ ! -f "$path" ]; then
              __haraspkgs_merged="$content"
              return 0
            fi

            if [ "$kind" = text ]; then
              current="$(cat -- "$path" && printf x)"
              current="''${current%x}"
              needle="''${content%$'\n'}"
              case "$current" in
                "" | *$'\n') ;;
                *) current="$current"$'\n' ;;
              esac
              if [[ "$current" == *"$needle"* ]]; then
                __haraspkgs_merged="$current"
              else
                __haraspkgs_merged="$current$content"
              fi
              return 0
            fi

            # shellcheck disable=SC2016 # $item is a yq variable, not a shell one
            __haraspkgs_merged="$(
              yq eval-all -p "$kind" -o "$kind" \
                '. as $item ireduce ({}; . * $item)' \
                "$path" <(printf '%s' "$content") && printf x
            )" || return 1
            __haraspkgs_merged="''${__haraspkgs_merged%x}"
          }
        '';

        # treefmt hands wrapped formatters a temporary copy of the text. The
        # bubblewrap profiles give them a private /tmp, so the copy goes in a
        # directory the wrapper is told to bind into the sandbox.
        formatFunction = ''
          __haraspkgs_format_content() {
            local path="$1" content="$2" formatter="$3" base scratch

            __haraspkgs_formatted="$content"
            if [ -z "$formatter" ]; then
              return 0
            fi

            base="''${TMPDIR:-/tmp}/haraspkgs"
            mkdir -p -- "$base" || return 1
            scratch="$(mktemp -d "$base/format.XXXXXX")" || return 1
            __haraspkgs_formatted="$(
              printf '%s' "$content" |
                ${selfLib.bwrap.scratchVariable}="$scratch" TMPDIR="$scratch" \
                  "$formatter" --quiet --stdin "$path" &&
                printf x
            )"
            rm -rf -- "$scratch"

            if [ "''${__haraspkgs_formatted: -1}" != x ]; then
              printf "format failed %s\n" "$path" >&2
              return 1
            fi
            __haraspkgs_formatted="''${__haraspkgs_formatted%x}"
          }
        '';

        writeFunctions = ''
          ${formatFunction}

          __haraspkgs_write_file() {
            local path="$1" content="$2" executable="$3" formatter="$4"
            local desired

            __haraspkgs_format_content "$path" "$content" "$formatter" || return 1
            desired="$__haraspkgs_formatted"

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

          ${mergeFunction}

          __haraspkgs_write_partial() {
            local path="$1" content="$2" executable="$3" formatter="$4" kind="$5"

            __haraspkgs_merge_partial "$path" "$content" "$kind" || return 1
            __haraspkgs_write_file "$path" "$__haraspkgs_merged" "$executable" "$formatter"
          }
        '';

        writeCall =
          file:
          let
            writer =
              if file.partial != null then
                "__haraspkgs_write_partial"
              else if file.text != null then
                "__haraspkgs_write_file"
              else
                "__haraspkgs_ensure_file";
          in
          builtins.concatStringsSep " " (
            [ writer ]
            ++ builtins.map lib.escapeShellArg [
              file.path
              (fileText (fileContent file))
              (lib.optionalString file.executable "1")
              (formatterFor file)
            ]
            ++ lib.optional (file.partial != null) (partialKind file)
          );

        writeCalls = builtins.concatStringsSep "\n" (builtins.map writeCall textFiles);

        # Ignored files are not in the repository source a check runs on.
        checkedFiles = builtins.filter (file: !file.ignore) textFiles;

        checkFunction = ''
          ${formatFunction}

          ${mergeFunction}

          __haraspkgs_check_content() {
            local path="$1" content="$2" executable="$3" formatter="$4"

            __haraspkgs_format_content "$path" "$content" "$formatter" || return 1
            if ! printf '%s' "$__haraspkgs_formatted" | cmp -s - "$path"; then
              printf "file differs from its generated text %s\n" "$path" >&2
              return 1
            fi

            if [ -n "$executable" ] && [ ! -x "$path" ]; then
              printf "file is not executable %s\n" "$path" >&2
              return 1
            elif [ -z "$executable" ] && [ -x "$path" ]; then
              printf "file is executable %s\n" "$path" >&2
              return 1
            fi
          }

          __haraspkgs_check_ensure() {
            if [ ! -f "$1" ]; then
              printf "file is missing %s\n" "$1" >&2
              return 1
            fi
          }

          __haraspkgs_check_text() {
            local path="$1" source="$2" executable="$3" formatter="$4" content

            content="$(cat -- "$source" && printf x)" || return 1
            __haraspkgs_check_content "$path" "''${content%x}" "$executable" "$formatter"
          }

          __haraspkgs_check_partial() {
            local path="$1" source="$2" executable="$3" formatter="$4" kind="$5" content

            content="$(cat -- "$source" && printf x)" || return 1
            __haraspkgs_merge_partial "$path" "''${content%x}" "$kind" || return 1
            __haraspkgs_check_content "$path" "$__haraspkgs_merged" "$executable" "$formatter"
          }
        '';

        # The expected text goes through a store file so the script that embeds
        # the check does not have to contain, and shellcheck, every file's text.
        checkCall =
          file:
          let
            expected = pkgs.writeText "expected" (fileText (fileContent file));
            checker =
              if file.partial != null then
                "__haraspkgs_check_partial"
              else if file.text != null then
                "__haraspkgs_check_text"
              else
                "__haraspkgs_check_ensure";
            arguments =
              if file.partial == null && file.text == null then
                [ file.path ]
              else
                [
                  file.path
                  (builtins.toString expected)
                  (lib.optionalString file.executable "1")
                  (formatterFor file)
                ]
                ++ lib.optional (file.partial != null) (partialKind file);
          in
          builtins.concatStringsSep " " ([ checker ] ++ builtins.map lib.escapeShellArg arguments)
          + " || status=1";

        checkCalls = builtins.concatStringsSep "\n" (builtins.map checkCall checkedFiles);

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
                    description = "Source file that will be linked to `${name}`, or merged into it when `partial` is set.";
                  };

                  partial = lib.mkOption {
                    type = lib.types.nullOr (
                      lib.types.attrTag (
                        lib.genAttrs partialKinds (
                          kind:
                          lib.mkOption {
                            type = lib.types.bool;
                            description = "Treat the file at `${name}` as ${kind} and merge `text` or `source` into it.";
                          }
                        )
                      )
                    );
                    default = null;
                    description = ''
                      Merge `text` or `source` into the existing file at `${name}` instead of
                      owning it. The tag picks the format: `text` appends the text when it is
                      missing, and `json`, `toml` and `yaml` merge recursively with the declared
                      values winning and lists replaced. Needs exactly one of `text` and `source`.
                    '';
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
                    default = config.source != null && config.partial == null;
                    defaultText = lib.literalExpression "config.source != null && config.partial == null";
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

            packages = builtins.map ({ package, ... }: package) linkFiles ++ lib.optional needsYq pkgs.yq-go;

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
                  unset -f __haraspkgs_write_file __haraspkgs_ensure_file \
                    __haraspkgs_merge_partial __haraspkgs_write_partial \
                    __haraspkgs_format_content
                  unset __haraspkgs_merged __haraspkgs_formatted
                '';
              }
            );
          }
          (lib.optionalAttrs (options ? format) {
            format.excludes = unformattedPaths;
          })
          # The condition must not read `enable`: its default forces the text,
          # which can be an IFD that must not be realized while listing checks.
          (lib.mkIf (files != [ ]) (
            lib.optionalAttrs (options ? check) {
              check.checks.file = {
                packages = lib.optional needsYq pkgs.yq-go;
                commands = [
                  {
                    header = "generated files";
                    text = ''
                      ${checkFunction}
                      status=0
                      ${checkCalls}
                      test "$status" -eq 0
                    '';
                  }
                ];
              };
            }
          ))
        ];
      };
  };
}
