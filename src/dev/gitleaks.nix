{
  self.devModules.gitleaks = {
    self = false;
    flake = true;
    value =
      {
        config,
        lib,
        options,
        pkgs,
        ...
      }:
      let
        format = pkgs.formats.toml { };

        settings = config.gitleaks.settings;

        settingsFile = format.generate "gitleaks.toml" settings;

        hasSettings = settings != { };

        package = pkgs.writeShellApplication {
          name = "dev-gitleaks";
          runtimeInputs = [ config.gitleaks.package ];
          text = ''
            gitleaks ${lib.optionalString hasSettings "--config ${settingsFile} "}"$@"
          '';
        };

        hasGit = options ? git;
        hasCheck = options ? check;

        integrations =
          lib.optionalAttrs hasGit {
            git.enable = lib.mkDefault true;
            git.hooks.pre-commit = {
              packages = [
                package
                config.gitleaks.gitPackage
              ];
              commands = "dev-gitleaks git --staged --pre-commit .";
            };
          }
          // lib.optionalAttrs hasCheck {
            check.checks.gitleaks = {
              packages = [
                package
                config.gitleaks.gitPackage
              ];
              commands = "dev-gitleaks dir .";
            };
          };
      in
      {
        options.gitleaks = {
          enable = lib.mkEnableOption "gitleaks";

          package = lib.mkPackageOption pkgs "gitleaks" { };

          gitPackage = lib.mkPackageOption pkgs "git" { };

          settings = lib.mkOption {
            type = format.type;
            default = { };
            description = "gitleaks configuration written to a TOML file.";
          };
        };

        config = lib.mkIf config.gitleaks.enable (
          {
            packages = [ package ];
          }
          // integrations
        );
      };
  };
}
