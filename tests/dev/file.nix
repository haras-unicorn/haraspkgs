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
}
