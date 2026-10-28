# Dev tests

`self.devTests` is an attribute set of dev shell module tests. Every entry is
realized under `self.lib.<system>.devTests.<name>` and, when `flake = true`,
becomes `perSystem.checks.dev-test-<name>`. Tests live in
`tests/dev/<module>.nix` and assert observable effects rather than evaluated
config.

## Shape

```nix
{
  self.devTests.example = {
    flake = true;

    value = {
      modules = [
        { pkgs, ... }: {
          packages = [ pkgs.hello ];
        }
      ];
      commands = [ "hello" ];
    };
  };
}
```

Each entry is a submodule with `self`, `flake`, and `value`. `value` holds the
test options.

## Options

<!-- markdownlint-disable MD013 -->

| Option                     | Type                     | Default | Description                                       |
| -------------------------- | ------------------------ | ------- | ------------------------------------------------- |
| `devTests.<name>.modules`  | list of deferred modules | `[]`    | Modules used to build the test shell.             |
| `devTests.<name>.commands` | commands                 | `[]`    | Commands run after the shell hook.                |
| `devTests.<name>.self`     | bool                     | `true`  | Include the test in `self.lib.<system>.devTests`. |
| `devTests.<name>.flake`    | bool                     | `false` | Emit the test as a per-system check.              |

<!-- markdownlint-enable MD013 -->

## Execution

The test is built by `harasPackages.makeDevTest` from the `dev` overlay. The
modules are evaluated into a shell with the same evaluator, default dev modules,
and shell overlay as the normal dev shells. In the build sandbox the test copies
`self.outPath` into a writable directory, runs the shell's `shellHook`, then
runs `commands`. The check overrides the shell's build phase, so it inherits the
shell's `env`, `nativeBuildInputs`, `inputsFrom`, and packages. It does not
invoke `nix develop`.

The check fails if the shell hook or any command exits non-zero.

## CI and self-only tests

`flake = true` tests become checks, so CI builds them on every supported system.
Use `flake = false` for tests that need bwrap or another environment-specific
tool; those tests stay in `self.lib.<system>.devTests` and are run locally.
`self` keeps its default `true`, so a test can be both local-only and visible in
the self mirror.

## Outputs

- `self.lib.<system>.devTests.<name>` is the made test derivation.
- Each test with `flake = true` becomes `perSystem.checks.dev-test-<name>`.
- `self = true` (the default) keeps the test in `self.lib.<system>.devTests`.

## Related

- [Test a dev shell](../guides/dev-tests.md)
- [How the repository is tested](../explanation/testing.md)
- [How dev shells are assembled](../explanation/dev-shells.md)
- [NixOS tests](nixos-tests.md)
