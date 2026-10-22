{ selfLib, ... }:

{
  self.devModules.git = {
    self = false;
    flake = true;
    value =
      {
        config,
        inputs,
        lib,
        options,
        pkgs,
        ...
      }:
      let
        git = config.git;

        gitignoreInput =
          if inputs ? github-gitignore then inputs.github-gitignore else selfLib.lib.inputs.github-gitignore;

        patternsText = lib.trim git.ignore.patterns;

        templatesText = lib.concatStringsSep "\n\n" (
          builtins.map (
            name:
            let
              source = "${gitignoreInput}/${name}.gitignore";
            in
            if builtins.pathExists source then
              ''
                # github/gitignore: ${name}.gitignore
                ${lib.trim (builtins.readFile source)}
              ''
            else
              throw "git.ignore.templates: ${name}.gitignore not found in the github-gitignore input"
          ) git.ignore.templates
        );

        ignoreText = lib.concatStringsSep "\n\n" (
          builtins.filter (text: text != "") [
            patternsText
            templatesText
          ]
        );

        attributesText = lib.trim git.attributes;

        hooks = lib.filterAttrs (_: hook: hook.enable) git.hooks;

        hasCli = options ? cli && config.cli.enable;

        cliPackage = config.passthru.cli or null;

        devExecutable = if cliPackage != null then lib.getExe cliPackage else "dev";

        quote = lib.escapeShellArg;

        mkHook = name: _: {
          inherit name;
          commandName = "hook-${name}";
        };

        enabledHooks = lib.mapAttrsToList mkHook hooks;

        hookCliCommands = lib.listToAttrs (
          builtins.map (hook: {
            name = hook.commandName;
            value = {
              description = "Run the ${hook.name} git hook.";
              inherit (hooks.${hook.name}) packages commands;
            };
          }) enabledHooks
        );

        hookFiles = builtins.map (hook: {
          inherit (hook) name;
          path = pkgs.writeTextFile {
            name = "haraspkgs-git-hook-${hook.name}";
            executable = true;
            text = ''
              #!${pkgs.runtimeShell}
              exec ${devExecutable} ${hook.commandName} "$@"
            '';
          };
        }) enabledHooks;

        hooksPackage =
          if enabledHooks == [ ] then
            null
          else
            pkgs.runCommand "haraspkgs-git-hooks" { } (
              "mkdir -p $out\n"
              + lib.concatMapStringsSep "\n" (
                hook: "install -m755 ${quote (toString hook.path)} \"$out\"/${quote hook.name}"
              ) hookFiles
            );

        gitWrapper =
          if hooksPackage == null then
            null
          else
            pkgs.harasPackages.makeBubblewrapWrapper {
              name = "git";
              package = git.package;
              runtimeInputs = [ git.package ] ++ lib.optional (cliPackage != null) cliPackage;
              env = {
                GIT_CONFIG_COUNT = "1";
                GIT_CONFIG_KEY_0 = "core.hooksPath";
                GIT_CONFIG_VALUE_0 = "${hooksPackage}";
              };
            };
      in
      {
        options.git = {
          enable = lib.mkEnableOption "git integration";

          package = lib.mkPackageOption pkgs "git" { };

          ignore.patterns = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Patterns added to the generated `.gitignore`.";
          };

          ignore.templates = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Template names read from the `github-gitignore` input.";
          };

          attributes = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Contents of the generated `.gitattributes`.";
          };

          hooks = lib.mkOption {
            default = { };
            description = "Git hooks exposed through the `dev` CLI.";
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, ... }:
                {
                  options = {
                    enable = lib.mkOption {
                      type = lib.types.bool;
                      default = true;
                      description = "Whether to generate the `${name}` hook.";
                    };

                    packages = lib.mkOption {
                      type = lib.types.listOf lib.types.package;
                      default = [ ];
                      description = "Packages available to the `${name}` hook.";
                    };

                    commands = lib.mkOption {
                      type = selfLib.dev.commands;
                      default = [ ];
                      description = "Commands run by the `${name}` hook.";
                    };
                  };
                }
              )
            );
          };
        };

        config = lib.mkIf git.enable {
          packages = [ (if gitWrapper == null then git.package else gitWrapper) ];

          file = lib.mkMerge [
            (lib.mkIf (ignoreText != "") {
              ".gitignore" = {
                text = ignoreText;
                format = false;
              };
            })
            (lib.mkIf (attributesText != "") {
              ".gitattributes" = {
                text = attributesText;
                format = false;
              };
            })
          ];

          cli = lib.mkIf hasCli {
            commands = hookCliCommands;
          };

          passthru.git = {
            hooks = hooksPackage;
            wrapper = gitWrapper;
          };
        };
      };
  };
}
