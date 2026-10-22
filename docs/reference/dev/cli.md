# CLI module

The `cli` module is exported through `flake.devModules.cli` and included in the
default group. It installs one `dev` command in the shell.

## Options

<!-- markdownlint-disable MD013 -->

| Field                             | Type            | Default | Description                             |
| --------------------------------- | --------------- | ------- | --------------------------------------- |
| `cli.enable`                      | bool            | `true`  | Whether to install the `dev` command.   |
| `cli.packages`                    | list of package | `[]`    | Packages available to every subcommand. |
| `cli.commands.<name>.enable`      | bool            | `true`  | Whether to expose the subcommand.       |
| `cli.commands.<name>.packages`    | list of package | `[]`    | Packages available to the subcommand.   |
| `cli.commands.<name>.commands`    | commands        | `[]`    | Commands run by the subcommand.         |
| `cli.commands.<name>.description` | string          | name    | Help text shown by `dev --help`.        |

<!-- markdownlint-enable MD013 -->

## Behavior

The module generates a shell application named `dev`. It changes to the flake
root and dispatches the first argument to a subcommand:

- `dev <name>` runs the commands registered at `cli.commands.<name>`.
- `dev --help` lists the enabled subcommands.
- `dev check` runs the checks registered by the `check` module directly.
- `dev format` runs the treefmt configuration registered by the `format` module
  directly.

The check and format subcommands exist only when their modules are present and
have something to run. The CLI renders commands with the same `commands` type
used by `shellHook`, so it prints the same headers and prompts. Headers and
blank separators are written to stderr, so stdout contains only the command
output.

## Relationship to flake actions

`dev check` and `dev format` do not call `nix flake check` or `nix fmt`. They
run the registered commands in the checkout, which keeps output readable and
avoids starting another Nix evaluation. The flake actions remain available for
CI and for callers who prefer them.

## Outputs

- `dev` in the shell `packages`.
- `dev check` when `check.checks` has enabled entries.
- `dev format` when `format.formatters` has enabled entries.
- `dev hook-<name>` when the git module has enabled hooks.

## Related

- [Add a dev command](../../guides/dev/cli.md)
- [The CLI module](../../explanation/dev/cli.md)
- [devModule](../dev-module.md)
