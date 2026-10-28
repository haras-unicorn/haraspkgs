# devModule

`self.devModules` and `self.devShells` are attribute sets of deferred modules.
Each entry is a submodule with `self`, `flake`, and `value`:

```nix
{
  self.devModules.example = {
    value =
      { pkgs, ... }:
      {
        packages = [ pkgs.hello ];
      };
  };
}
```

Every dev module shipped by `haraspkgs` uses `self = false; flake = true;`. It
is exported through `flake.devModules` and consumed by the shell evaluator.
Downstream dev modules keep the default `self = true; flake = false;` unless
they are intentionally exported, in which case they should also set
`flake = true` and `self = false` to avoid a double import.

## Evaluation

For each entry in `self.devShells`, `haraspkgs` evaluates the module per system
with `lib.evalModules`. The evaluation receives:

- the per-system `pkgs`,
- the flake `self`,
- the flake `inputs`,
- the flake-parts `specialArgs` and its keys,
- the exported `flake.devModules.default` group from haraspkgs,
- the downstream `self.lib.devModules.default` group,
- the shell module itself.

Before evaluation, the per-system `pkgs` is extended with the shell overlay, so
`pkgs.harasPackages.makeBubblewrapWrapper` is available to dev modules. The same
overlay is part of the flake's own package set for now. See
[Overlays](overlays.md).

The evaluator takes the shell fields from the resulting config (`name`,
`packages`, `buildInputs`, `nativeBuildInputs`, `inputsFrom`, `env`, and
`passthru`), renders `shellHook`, and passes them to `pkgs.mkShell`. The shell
is emitted as `perSystem.devShells.<name>`.

## Shell form

Every downstream `self.devModules` entry with `self = true` is aggregated into
the default module imported by each shell. Haraspkgs-provided dev modules arrive
through `flake.devModules` instead, so they are not part of downstream `self`. A
shell only needs to add its own overrides:

```nix
{
  self.devShells.example = {
    value = {
      env.EXAMPLE = "1";
    };
  };
}
```

## Module references

- [Shell module](dev/shell.md)
- [File module](dev/file.md)
- [Git module](dev/git.md)
- [Gitleaks module](dev/gitleaks.md)
- [Language registry module](dev/languages.md)
- [EditorConfig module](dev/editorconfig.md)
- [License module](dev/license.md)
- [Code of conduct module](dev/code-of-conduct.md)
- [Check module](dev/check.md)
- [Format module](dev/format.md)
- [CLI module](dev/cli.md)
- [Workflows module](dev/workflows.md)

## Outputs

- `flake.devModules` contains every haraspkgs-provided dev module and
  `default.imports`.
- `self.lib.devModules` contains the downstream-owned dev modules.
- Each shell becomes `perSystem.devShells.<name>`.
- `self.lib.<system>.devShells.<name>` contains the evaluated shell.
- Shell `passthru.checks` becomes `perSystem.checks.<shell>-<name>`.
- `self.devTests` entries with `flake = true` become
  `perSystem.checks.dev-test-<name>`.
- The `default` shell's `passthru.formatter` becomes `perSystem.formatter`.

## Related

- [Add a dev shell](../guides/dev-shells.md)
- [Test a dev shell](../guides/dev-tests.md)
- [How dev shells are assembled](../explanation/dev-shells.md)
