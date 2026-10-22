{
  self.devTests.workflows = {
    flake = true;
    value = {
      modules = [
        ({ pkgs, ... }: {
          workflows.example = {
            installable = ".#docs";
            on.push.branches = [ "main" ];
            permissions.pages = "write";
            steps = [ { run = "echo extra-step"; } ];
          };

          format.formatters.prettier = {
            packages = [ pkgs.prettier ];
            command = "prettier";
            options = [ "--write" ];
            includes = [ "*.yaml" ];
          };
        })
      ];
      commands = [
        "test -f .github/workflows/example.yaml"
        "grep -q 'nix build --show-trace .#docs' .github/workflows/example.yaml"
        "grep -q 'echo extra-step' .github/workflows/example.yaml"
        "grep -q 'main' .github/workflows/example.yaml"
        "grep -q 'pages' .github/workflows/example.yaml"
      ];
    };
  };
}
