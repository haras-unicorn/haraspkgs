{
  self.devTests.code-of-conduct = {
    flake = true;
    value = {
      modules = [
        {
          codeOfConduct.contributorCovenant = {
            enable = true;
            path = "CODE_OF_CONDUCT.example.md";
            source = ../fixtures/code-of-conduct.md;
          };
        }
      ];
      commands = [
        "test -f CODE_OF_CONDUCT.example.md"
        "grep -q 'Contributor Covenant' CODE_OF_CONDUCT.example.md"
        "grep -q 'Be respectful' CODE_OF_CONDUCT.example.md"
      ];
    };
  };
}
