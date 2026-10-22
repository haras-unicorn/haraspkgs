# Check module

The `check` module is exported through `flake.devModules.check` and included in
the default group. It turns named command lists into check derivations.

## Options

<!-- markdownlint-disable MD013 -->

| Field                          | Type            | Default | Description                        |
| ------------------------------ | --------------- | ------- | ---------------------------------- |
| `check.packages`               | list of package | `[]`    | Packages available to every check. |
| `check.checks.<name>.enable`   | bool            | `true`  | Whether to expose the check.       |
| `check.checks.<name>.packages` | list of package | `[]`    | Packages available to this check.  |
| `check.checks.<name>.commands` | commands        | `[]`    | Commands run by this check.        |

<!-- markdownlint-enable MD013 -->

## Behavior

For each enabled entry in `check.checks`, the module:

1. copies `self.outPath` to a writable directory,
2. runs the check's commands from that directory,
3. creates the derivation output.

The commands use the same type as `shellHook`. `check.packages` and the check's
own `packages` become `nativeBuildInputs`.

## Outputs

- `passthru.checks.<name>` on each evaluated shell.
- `perSystem.checks.<shell>-<name>` in the flake.
- `self.lib.<system>.devShells.<shell>.passthru.checks.<name>` in the self
  mirror.

## Related

- [Configure checks](../../guides/dev/check.md)
- [The check module](../../explanation/dev/check.md)
- [devModule](../dev-module.md)
