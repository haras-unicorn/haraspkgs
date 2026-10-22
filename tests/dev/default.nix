{ config, ... }:

{
  self.devTests.default = {
    flake = true;
    value = {
      modules = [ config.self.devShells.default.value ];
      commands = [
        "test ! -e .editorconfig"
        "test ! -e .helix/languages.toml"
        "test -f .gitattributes"
        "test -f .gitignore"
        "test -f .github/workflows/check.yaml"
        "test -f .github/workflows/docs.yaml"
        "test -f .github/workflows/release.yaml"
        "grep -q 'nix flake check' .github/workflows/check.yaml"
        "dev --help"
        ''test "$(flake-root)" = "$PWD"''
      ];
    };
  };
}
