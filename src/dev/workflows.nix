{ selfLib, ... }:

{
  self.devModules.workflows = {
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
        rendered = lib.mapAttrs (name: workflow: selfLib.workflows.render name workflow) config.workflows;

        prettier = lib.attrByPath [ "format" "formatters" "prettier" ] null config;

        hasPrettier = prettier != null && prettier.enable && prettier.packages != [ ];

        formatRendered =
          path:
          lib.optionalString hasPrettier ''
            ${pkgs.prettier}/bin/prettier ${lib.escapeShellArgs prettier.options} ${path}
          '';

        renderedFiles = lib.mapAttrsToList (name: text: {
          name = "${name}.yaml";
          path = pkgs.writeText "${name}.yaml" text;
        }) rendered;

        renderedDir = pkgs.runCommand "rendered-workflows" { } ''
          mkdir -p $out
          ${lib.concatStrings (builtins.map (file: "cp ${file.path} $out/${file.name}\n") renderedFiles)}
        '';

        workflowsCheck = pkgs.runCommand "workflows-check" { } ''
          cp -r ${renderedDir} rendered
          chmod -R u+w rendered
          ${formatRendered "rendered/*.yaml"}
          diff -ru ${self.outPath}/.github/workflows rendered
          touch $out
        '';
      in
      {
        options.workflows = lib.mkOption {
          default = { };
          description = "GitHub Actions workflows rendered into `.github/workflows`.";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "Workflow name written to the YAML file.";
                  };

                  installable = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = ".#${name}";
                    description = "Flake installable built by the workflow. Set to null to skip the build step.";
                  };

                  on = lib.mkOption {
                    type = lib.types.attrs;
                    default = { };
                    description = "GitHub Actions `on` trigger configuration.";
                  };

                  permissions = lib.mkOption {
                    type = lib.types.attrsOf lib.types.str;
                    default = { };
                    description = "GitHub Actions permissions. Defaults to `contents = read`.";
                  };

                  env = lib.mkOption {
                    type = lib.types.attrs;
                    default = { };
                    description = "Workflow-level environment variables.";
                  };

                  matrix = lib.mkOption {
                    type = lib.types.nullOr (lib.types.attrsOf lib.types.anything);
                    default = null;
                    description = "Job matrix. When it contains `os`, the job runs on `\${{ matrix.os }}`.";
                  };

                  runsOn = lib.mkOption {
                    type = lib.types.str;
                    default = "ubuntu-latest";
                    description = "Runner used when no `os` matrix is configured.";
                  };

                  jobName = lib.mkOption {
                    type = lib.types.str;
                    default = "build";
                    description = "Name of the generated job.";
                  };

                  installNix = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                    description = "Whether to install Nix with `cachix/install-nix-action`.";
                  };

                  installNixExtraConfig = lib.mkOption {
                    type = lib.types.lines;
                    default = ''
                      experimental-features = nix-command flakes auto-allocate-uids cgroups
                      auto-allocate-uids = true
                    '';
                    description = "Extra configuration passed to `install-nix-action`.";
                  };

                  cachix = lib.mkOption {
                    type = lib.types.nullOr (
                      lib.types.submodule {
                        options = {
                          name = lib.mkOption {
                            type = lib.types.str;
                            default = "haras";
                            description = "Cachix cache name.";
                          };

                          extraPullNames = lib.mkOption {
                            type = lib.types.nullOr lib.types.str;
                            default = "haras-releases";
                            description = "Additional comma-separated caches to pull from.";
                          };

                          authToken = lib.mkOption {
                            type = lib.types.nullOr lib.types.str;
                            default = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
                            description = "Cachix authentication token expression.";
                          };
                        };
                      }
                    );
                    default = { };
                    description = "Cachix configuration. Set to null to skip the Cachix step.";
                  };

                  steps = lib.mkOption {
                    type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
                    default = [ ];
                    description = "Extra steps appended after the base steps.";
                  };

                  jobs = lib.mkOption {
                    type = lib.types.attrsOf lib.types.anything;
                    default = { };
                    description = "Extra jobs merged with the generated job.";
                  };
                };
              }
            )
          );
        };

        config = lib.mkIf (config.workflows != { }) {
          file = lib.mapAttrs' (
            name: text:
            lib.nameValuePair ".github/workflows/${name}.yaml" {
              inherit text;
            }
          ) rendered;

          passthru.checks.workflows = workflowsCheck;
        };
      };
  };
}
