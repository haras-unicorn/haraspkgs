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
