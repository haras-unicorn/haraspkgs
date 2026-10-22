{
  selfLib,
  ...
}:

{
  self.unitTests.dev = {
    test-extract-passthru = {
      expr = selfLib.dev.extractPassthruDevShellAttrs {
        default = {
          passthru.checks = {
            lint = "lint-derivation";
            format = "format-derivation";
          };
        };
        extra = {
          passthru.checks = {
            test = "test-derivation";
          };
        };
      } "checks" (_: true);
      expected = {
        default-lint = "lint-derivation";
        default-format = "format-derivation";
        extra-test = "test-derivation";
      };
    };

    test-extract-filter = {
      expr = selfLib.dev.extractPassthruDevShellAttrs {
        default = {
          passthru.packages = {
            keep = "kept";
            drop = "dropped";
          };
        };
      } "packages" (value: value == "kept");
      expected = {
        default-keep = "kept";
      };
    };

    test-extract-missing-attr = {
      expr = selfLib.dev.extractPassthruDevShellAttrs {
        default = { };
      } "checks" (_: true);
      expected = { };
    };

    test-commands-check = {
      expr = builtins.all selfLib.dev.commands.check [
        "pwd"
        [ ]
        [ "pwd" ]
        [ { text = "pwd"; } ]
        {
          text = "pwd";
        }
      ];
      expected = true;
    };

    test-commands-check-rejects-invalid = {
      expr = builtins.all (value: !(selfLib.dev.commands.check value)) [
        1
        { }
        [ 1 ]
        [ { text = 1; } ]
      ];
      expected = true;
    };

    test-commands-merge = {
      expr =
        selfLib.dev.commands.merge
          [ ]
          [
            { value = "pwd"; }
            {
              value = [
                "ls"
                {
                  text = "cd /tmp";
                }
              ];
            }
          ];
      expected = [
        { text = "pwd"; }
        { text = "ls"; }
        { text = "cd /tmp"; }
      ];
    };

    test-concat-commands-string = {
      expr = selfLib.dev.concatCommands [ "echo 'Hello, world!'" ];
      expected = ''
        # shellcheck disable=SC2016
        printf "%s\n\n" '> echo '\'''Hello, world!'\'''' >&2
        echo 'Hello, world!'
        printf "\n" >&2
      '';
    };

    test-concat-commands-preserves-context = {
      expr = builtins.hasContext (
        selfLib.dev.concatCommands [
          "echo ${builtins.toFile "concat-commands-dependency" "dependency"}"
        ]
      );
      expected = true;
    };

    test-concat-commands-empty = {
      expr = selfLib.dev.concatCommands [ "" ];
      expected = "";
    };

    test-concat-commands-depth = {
      expr = selfLib.dev.concatCommands [
        {
          text = "ls -la";
          depth = 2;
        }
      ];
      expected = ''
        # shellcheck disable=SC2016
        printf "%s\n\n" '>> ls -la' >&2
        ls -la
        printf "\n" >&2
      '';
    };

    test-concat-commands-mixed = {
      expr = selfLib.dev.concatCommands [
        "pwd"
        {
          text = "cd /tmp";
          prompt = "##";
        }
      ];
      expected = ''
        # shellcheck disable=SC2016
        printf "%s\n\n" '> pwd' >&2
        pwd
        printf "\n" >&2

        # shellcheck disable=SC2016
        printf "%s\n\n" '## cd /tmp' >&2
        cd /tmp
        printf "\n" >&2
      '';
    };

    test-concat-commands-filtered-invalid = {
      expr = selfLib.dev.concatCommands [
        ""
        { }
        "valid"
        { text = ""; }
      ];
      expected = ''
        # shellcheck disable=SC2016
        printf "%s\n\n" '> valid' >&2
        valid
        printf "\n" >&2
      '';
    };
  };
}
