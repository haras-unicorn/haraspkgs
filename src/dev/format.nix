{
  self.devModules.format = {
    self = false;
    flake = true;
    value =
      {
        config,
        lib,
        pkgs,
        self,
        ...
      }:
      let
        formatters = lib.filterAttrs (_: formatter: formatter.enable) config.format.formatters;

        treefmtConfig = (pkgs.formats.toml { }).generate "haraspkgs-treefmt.toml" {
          formatter = lib.mapAttrs (_: formatter: {
            command = formatter.command;
            options = formatter.options;
            includes = formatter.includes;
            excludes = formatter.excludes;
          }) formatters;
        };

        runtimeInputs = [
          config.format.treefmtPackage
        ]
        ++ lib.flatten (builtins.map (formatter: formatter.packages) (builtins.attrValues formatters))
        ++ config.format.packages;

        formatterPackage = pkgs.writeShellApplication {
          name = "format";
          inherit runtimeInputs;
          text = ''
            exec treefmt --no-cache --tree-root . --walk filesystem \
              --config-file ${treefmtConfig} "$@"
          '';
        };

        formatCheck =
          pkgs.runCommand "format-check"
            {
              src = self.outPath;
              nativeBuildInputs = runtimeInputs;
            }
            ''
              cp -r $src source
              chmod -R u+w source
              cd source
              treefmt --no-cache --fail-on-change --tree-root . --walk filesystem --config-file ${treefmtConfig} .
              touch $out
            '';
      in
      {
        options.format = {
          treefmtPackage = lib.mkPackageOption pkgs "treefmt" { };

          packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Additional packages available to the formatter.";
          };

          command = lib.mkOption {
            type = lib.types.nullOr lib.types.package;
            default = null;
            internal = true;
            description = "Formatter package used by generated-file shell hooks.";
          };

          formatters = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, ... }:
                {
                  options = {
                    enable = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Whether to run the formatter at `${name}`.";
                    };

                    packages = lib.mkOption {
                      type = lib.types.listOf lib.types.package;
                      default = [ ];
                      description = "Packages available to the formatter at `${name}`.";
                    };

                    command = lib.mkOption {
                      type = lib.types.str;
                      description = "Formatter command run by treefmt.";
                    };

                    options = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = "Arguments passed to the formatter at `${name}`.";
                    };

                    includes = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = "Files matched by the formatter at `${name}`.";
                    };

                    excludes = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = "Files excluded by the formatter at `${name}`.";
                    };
                  };
                }
              )
            );
            default = { };
            description = "Formatters registered with treefmt.";
          };
        };

        config = lib.mkMerge [
          (lib.mkIf (formatters != { }) {
            format.command = formatterPackage;
            passthru.checks.format = formatCheck;
            passthru.formatter = formatterPackage;
          })
          (lib.mkIf (formatters != { }) {
            cli.commands.format = {
              description = "Format the checkout with treefmt.";
              packages = [ formatterPackage ];
              commands = [
                {
                  header = "treefmt";
                  text = "${formatterPackage}/bin/format \"$@\"";
                }
              ];
            };
          })
        ];
      };
  };
}
