# Unit tests

Unit tests use the `self` namespace. Haraspkgs routes them to nix-unit and adds
the `checks.<system>.nix-unit` derivation. They cover pure helpers in `src/lib/`
only; use [dev tests](dev-tests.md) for dev module behavior and
`perSystem.checks` for packages and generated files.

## Options

<!-- markdownlint-disable MD013 -->

| Option                     | Type  | Default | Description                      |
| -------------------------- | ----- | ------- | -------------------------------- |
| `self.unitTests`           | suite | `{}`    | System-agnostic nix-unit suites. |
| `perSystem.self.unitTests` | suite | `{}`    | Per-system nix-unit suites.      |

<!-- markdownlint-enable MD013 -->

A suite is an attribute set of nix-unit tests:

```nix
self.unitTests.default = {
  test-one = {
    expr = 1;
    expected = 1;
  };
};
```

Per-system suites can use `pkgs` and `system`:

```nix
perSystem = { pkgs, ... }: {
  self.unitTests.default = {
    test-hello = {
      expr = pkgs.hello.name;
      expected = "hello";
    };
  };
};
```

## Input

The module uses the downstream `nix-unit` input when it is present and falls
back to the haraspkgs `nix-unit` input otherwise. Downstream flakes do not need
to add `nix-unit` themselves.

## Outputs

- `checks.<system>.nix-unit` runs the per-system suites and the system-agnostic
  suites.
- `self.lib.unitTests` mirrors the system-agnostic suites.

Do not define `flake.tests` or `perSystem.nix-unit.tests` directly. Those are
implementation details owned by the unit-tests module.

## Related

- [How the repository is tested](../explanation/testing.md)
- [Dev tests](dev-tests.md)
- [Configure checks](../guides/dev/check.md)
- [How dev shells are assembled](../explanation/dev-shells.md)
