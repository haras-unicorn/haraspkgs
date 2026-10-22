{
  self.devTests.check = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          check.checks.example = {
            packages = [ pkgs.hello ];
            commands = "hello --greeting check-ok > check.txt";
          };
        })
      ];
      commands = [
        "dev check"
        "grep -qx 'check-ok' check.txt"
      ];
    };
  };
}
