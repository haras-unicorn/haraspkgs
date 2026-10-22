{
  self.devModules.file = {
    self = false;
    flake = true;
    value =
      {
        lib,
        config,
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

        formattedFiles = builtins.filter (file: file.format) textFiles;

        formatEnabled = formatCommand != null && formattedFiles != [ ];

        formatSetup = lib.optionalString formatEnabled "declare -a __haraspkgs_format_paths=()\n";

        appendFormatPath =
          file:
          lib.optionalString (
            formatEnabled && file.format
          ) "__haraspkgs_format_paths+=(${lib.escapeShellArg file.path})";

        writeFiles = builtins.map (
          file:
          let
            path = lib.escapeShellArg file.path;
            dir = lib.escapeShellArg (builtins.dirOf file.path);
            content = fileText (if file.text != null then file.text else file.ensure);
            writeContent = "printf '%s' ${lib.escapeShellArg content} > ${path}";
            makeExecutable = lib.optionalString file.executable "chmod +x ${path}";
            appendFormat = appendFormatPath file;
          in
          {
            command = ''
              mkdir -p ${dir}
            ''
            + lib.optionalString (file.text != null) ''
              rm -f ${path}
            ''
            + (
              if file.text != null then
                ''
                  ${writeContent}
                  ${makeExecutable}
                  ${appendFormat}
                  printf "write %s\n" ${path} >&2
                ''
              else
                ''
                  if [ ! -f ${path} ]; then
                    ${writeContent}
                    ${makeExecutable}
                    ${appendFormat}
                  fi
                  printf "ensure %s\n" ${path} >&2
                ''
            );
          }
        ) textFiles;

        writeCommands =
          formatSetup + builtins.concatStringsSep "\n" (builtins.map (file: file.command) writeFiles);

        formatHook = lib.optional formatEnabled {
          header = "formatting generated files";
          text = ''
            if [ "''${#__haraspkgs_format_paths[@]}" -gt 0 ]; then
              ${formatCommand}/bin/format "''${__haraspkgs_format_paths[@]}"
            fi
          '';
        };

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

        linkCommands = builtins.concatStringsSep "\n" (
          builtins.map (
            file:
            let
              path = lib.escapeShellArg file.path;
              dir = lib.escapeShellArg (builtins.dirOf file.path);
              source = lib.escapeShellArg file.source;
            in
            ''
              mkdir -p ${dir}
              ln -sfn ${source} ${path}
              printf "link %s\n" ${path} >&2
            ''
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
                    description = "Format the generated file when the shell starts.";
                  };

                  executable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = "Whether to make the generated file executable.";
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

        config = {
          file.".gitignore".text = lib.mkIf (ignoreText != "") (lib.mkBefore ignoreText);

          packages = builtins.map ({ package, ... }: package) linkFiles;

          shellHook = lib.mkBefore (
            lib.optional (linkCommands != "") {
              text = linkCommands;
              header = "linking";
            }
            ++ lib.optional (writeCommands != "") {
              text = writeCommands;
              header = "writing";
            }
            ++ formatHook
          );
        };
      };
  };
}
