{
  self.devTests.file = {
    flake = true;
    value = {
      modules = [
        {
          file = {
            ".test/generated.txt".text = "generated";
            ".test/ensured.txt".ensure = "ensured";
            ".test/executable.sh" = {
              text = "#!/bin/sh";
              executable = true;
            };
            ".test/linked.txt".source = ../fixtures/linked.txt;
            ".test/ignored.txt" = {
              text = "ignored";
              ignore = true;
            };
          };
        }
      ];
      commands = [
        ''test "$(cat .test/generated.txt)" = generated''
        ''test "$(cat .test/ensured.txt)" = ensured''
        "test -x .test/executable.sh"
        "test -L .test/linked.txt"
        ''test "$(cat .test/linked.txt)" = linked''
        "grep -qx '/.test/ignored.txt' .gitignore"
      ];
    };
  };

  self.devTests.file-partial = {
    flake = true;
    value = {
      modules = [
        (
          { lib, ... }:
          {
            file = {
              ".test/Cargo.toml" = {
                text = ''
                  [lints.clippy]
                  unwrap_used = "deny"
                '';
                partial.toml = true;
              };
              ".test/source.toml" = {
                source = ../fixtures/partial.toml;
                partial.toml = true;
              };
              ".test/data.json" = {
                text = ''{"b": 2}'';
                partial.json = true;
              };
              ".test/notes.txt" = {
                text = "added";
                partial.text = true;
              };
              ".test/present.txt" = {
                text = "present";
                partial.text = true;
              };
              ".test/missing.toml" = {
                text = ''key = "value"'';
                partial.toml = true;
              };
            };
            shellHook = lib.mkOrder 100 ''
              mkdir -p .test
              printf '# manual\n[lints.clippy]\nunwrap_used = "warn"\nmanual = "allow"\n' > .test/Cargo.toml
              printf '[package]\nname = "x"\n' > .test/source.toml
              printf '{"a": 1, "b": 1}\n' > .test/data.json
              printf 'first\n' > .test/notes.txt
              printf 'before\npresent\nafter\n' > .test/present.txt
            '';
          }
        )
      ];
      commands = [
        "grep -qx '# manual' .test/Cargo.toml"
        "grep -qx 'unwrap_used = \"deny\"' .test/Cargo.toml"
        "grep -qx 'manual = \"allow\"' .test/Cargo.toml"
        "grep -qx 'name = \"x\"' .test/source.toml"
        "grep -qx 'unsafe_code = \"forbid\"' .test/source.toml"
        "test ! -L .test/source.toml"
        ''test "$(yq -p json '.a + .b' .test/data.json)" = 3''
        ''test "$(cat .test/notes.txt)" = "$(printf 'first\nadded')"''
        ''test "$(cat .test/present.txt)" = "$(printf 'before\npresent\nafter')"''
        ''test "$(cat .test/missing.toml)" = 'key = "value"' ''
        "dev check"
        "sed -i 's/deny/warn/' .test/Cargo.toml"
        "! dev check"
      ];
    };
  };

  self.devTests.file-check = {
    flake = true;
    value = {
      modules = [
        {
          file = {
            ".test/generated.txt".text = "generated";
            ".test/ensured.txt".ensure = "ensured";
            ".test/executable.sh" = {
              text = "#!/bin/sh";
              executable = true;
            };
            ".test/ignored.txt" = {
              text = "ignored";
              ignore = true;
            };
            ".test/linked.txt".source = ../fixtures/linked.txt;
          };
        }
      ];
      commands = [
        "dev check"

        "echo drift >> .test/generated.txt"
        "! dev check"
        "printf 'generated\\n' > .test/generated.txt"
        "dev check"

        "echo edited > .test/ensured.txt"
        "dev check"
        "rm .test/ensured.txt"
        "! dev check"
        "echo edited > .test/ensured.txt"

        "chmod -x .test/executable.sh"
        "! dev check"
        "chmod +x .test/executable.sh"
        "chmod +x .test/generated.txt"
        "! dev check"
        "chmod -x .test/generated.txt"

        "echo edited > .test/ignored.txt"
        "rm .test/linked.txt"
        "dev check"
      ];
    };
  };

  self.devTests.file-format-scratch = {
    flake = true;
    value = {
      modules = [
        (
          { pkgs, ... }:
          let
            formatter = pkgs.writeShellScriptBin "test-formatter" ''
              for file in "$@"; do
                case "$(realpath "$file")" in
                  */haraspkgs/format.*/*) printf 'good\n' > "$file" ;;
                  *) printf 'bad\n' > "$file" ;;
                esac
              done
            '';
          in
          {
            file."scratch-target.txt".text = "input";
            format.formatters.example = {
              packages = [ formatter ];
              command = "test-formatter";
              includes = [ "*.txt" ];
            };
          }
        )
      ];
      commands = [
        "grep -qx good scratch-target.txt"
        "dev check"
        ''test -z "$(ls -A "''${TMPDIR:-/tmp}/haraspkgs")"''
      ];
    };
  };

  self.devTests.file-unchanged = {
    flake = true;
    value = {
      modules = [
        (
          { lib, ... }:
          {
            file.".test/current.txt".text = "current";
            file.".test/changed.txt".text = "new";
            shellHook = lib.mkOrder 100 ''
              mkdir -p .test
              printf 'current\n' > .test/current.txt
              printf 'old\n' > .test/changed.txt
              touch -d @946684800 .test/current.txt .test/changed.txt
            '';
          }
        )
      ];
      commands = [
        ''test "$(stat -c %Y .test/current.txt)" = 946684800''
        ''test "$(cat .test/changed.txt)" = new''
        ''test "$(stat -c %Y .test/changed.txt)" != 946684800''
      ];
    };
  };
}
