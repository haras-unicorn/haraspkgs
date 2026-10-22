{
  self.devTests.cli = {
    flake = true;
    value = {
      modules = [
        {
          cli.commands.example = {
            description = "Example command.";
            commands = "printf 'example-ok\\n' > cli.txt";
          };
        }
      ];
      commands = [
        "dev --help > help.txt"
        "grep -q 'example' help.txt"
        "dev example"
        "grep -qx example-ok cli.txt"
        "if dev missing-command > /dev/null 2>&1; then exit 1; fi"
      ];
    };
  };
}
