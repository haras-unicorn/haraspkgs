# The CLI module

The `cli` module gives every dev shell one `dev` entrypoint. It replaces a
family of generated `dev-*` commands with named subcommands.

## Why one entrypoint

`dev --help` is the list of things a repository can do. A new contributor does
not need to discover whether the command is called `dev-format`, `dev-lint`, or
`treefmt`. The first word is always `dev`; the second word is the action.

The module also gives arbitrary commands a home. A repository can register a
one-off maintenance task next to the standard check and format actions without
adding another executable name.

## Why the CLI runs commands directly

`dev check` and `dev format` do not proxy through `nix flake check` and
`nix fmt`.

- The check commands are already registered as derivations. The CLI runs the
  same command text in the checkout, so the output is immediate and readable.
- `nix flake check` starts another evaluation and builds every check in a
  sandbox copy. That is the right behavior for CI, but it hides the individual
  commands from the developer.
- `nix fmt` is still the canonical formatter output. `dev format` runs the same
  treefmt configuration directly, which is convenient when iterating on files.

The flake actions remain the source of truth for CI. The CLI is the interactive
view of the same definitions.

## Printing

CLI commands use the same `commands` renderer as `shellHook`. The renderer
prints a prompt header before each command, so `dev check` shows which check is
running and `dev format` shows the treefmt invocation. Headers and separators go
to stderr, leaving stdout for the command's own output. That keeps commands
pluggable into pipes and other shell commands. A command can override the header
with `header` and the prompt depth with `depth`.

## Module integration

The `check`, `format`, and `git` modules do not need a separate CLI
implementation. When the `cli` option is present, they register
`cli.commands.check`, `cli.commands.format`, and `cli.commands.hook-<name>`. The
CLI module discovers those entries like any other subcommand. That keeps the
module dependency one-way: `cli` knows how to render subcommands; the other
modules know what their actions run.

## Related

- [Add a dev command](../../guides/dev/cli.md)
- [CLI reference](../../reference/dev/cli.md)
- [The check module](check.md)
- [The format module](format.md)
