{
  selfLib,
  ...
}:

{
  self.devModules.cli = {
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
        commands = lib.filterAttrs (_: command: command.enable) config.cli.commands;
        commandNames = builtins.attrNames commands;

        commandBranches = lib.concatMapStringsSep "\n" (
          name:
          if builtins.match "[A-Za-z0-9][A-Za-z0-9_-]*" name == null then
            throw "cli.commands name '${name}' must match [A-Za-z0-9][A-Za-z0-9_-]*"
          else
            let
              command = commands.${name};
            in
            ''
              ${name})
                shift
                ${selfLib.dev.concatCommands command.commands}
                ;;
            ''
        ) commandNames;

        usageLines = lib.concatMapStringsSep "\n" (
          name: "  ${name}  ${commands.${name}.description}"
        ) commandNames;

        cliPackage = pkgs.writeShellApplication {
          name = "dev";

          runtimeInputs = [
            pkgs.${selfLib.overlays.namespace}.flake-root
          ]
          ++ config.cli.packages
          ++ lib.flatten (builtins.map (command: command.packages) (builtins.attrValues commands));

          text = ''
            cd "$(flake-root)"

            usage() {
              cat <<'EOF'
            Usage: dev <command> [args...]

            Commands:
            ${usageLines}
            EOF
            }

            case "''${1:-}" in
              ""|-h|--help)
                usage
                ;;
            ${commandBranches}
              *)
                printf 'unknown command: %s\n\n' "$1" >&2
                usage >&2
                exit 1
                ;;
            esac
          '';
        };
      in
      {
        options = {
          cli = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether to install the `dev` command.";
            };

            packages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = "Packages available to every `dev` subcommand.";
            };

            commands = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule (
                  { name, ... }:
                  {
                    options = {
                      enable = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                        description = "Whether to expose the `${name}` subcommand.";
                      };

                      description = lib.mkOption {
                        type = lib.types.str;
                        default = name;
                        description = "Help text for the `${name}` subcommand.";
                      };

                      packages = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = "Packages available to the `${name}` subcommand.";
                      };

                      commands = lib.mkOption {
                        type = selfLib.dev.commands;
                        default = [ ];
                        description = "Commands run by the `${name}` subcommand.";
                      };
                    };
                  }
                )
              );
              default = { };
              description = "Subcommands exposed by the `dev` command.";
            };
          };
        };

        config = lib.mkIf (config.cli.enable && commands != { }) {
          packages = [ cliPackage ];
          passthru.cli = cliPackage;
        };
      };
  };
}
