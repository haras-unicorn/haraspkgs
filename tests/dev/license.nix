{
  self.devTests.license = {
    flake = true;
    value = {
      modules = [
        {
          license = {
            enable = true;
            spdx = "MIT";
            path = "LICENSE.example";
            source = ../fixtures/license.txt;
            attrs."<year> <copyright holders>" = "2026 Haras";
          };
        }
      ];
      commands = [
        "test -f LICENSE.example"
        "grep -q 'Copyright (c) 2026 Haras' LICENSE.example"
        "! grep -q '<year>' LICENSE.example"
      ];
    };
  };
}
