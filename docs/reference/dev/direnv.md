# Direnv module

The `direnv` module is exported through `flake.devModules.direnv` and included
in the default group. It writes `.envrc` through the `file` module.

## Options

<!-- markdownlint-disable MD013 -->

| Field                | Type            | Default                  | Description                           |
| -------------------- | --------------- | ------------------------ | ------------------------------------- |
| `direnv.enable`      | bool            | `false`                  | Generate `.envrc`.                    |
| `direnv.watch.files` | list of strings | module files             | Files whose changes reload the shell. |
| `direnv.watch.dirs`  | list of strings | module directories       | Directories watched recursively.      |
| `direnv.useFlake`    | list of strings | `[ "." "--show-trace" ]` | Arguments passed to `use flake`.      |
| `direnv.extra`       | lines           | `""`                     | Lines added before `use flake`.       |

<!-- markdownlint-enable MD013 -->

## Generated file

`.envrc` is written by `file.".envrc"` with `format = false`, in this order:

1. the `extra` lines,
2. one `watch_file <path>` per entry of `watch.files`, then one
   `watch_dir <path>` per entry of `watch.dirs`,
3. `use flake <useFlake>`,
4. the same watch lines again.

All paths are relative to the repository root. The watches appear twice on
purpose; see [why direnv watches the Nix tree](../../explanation/dev/direnv.md).

## Defaults

"Module files" and "module directories" are the path entries of the `modules`
argument of [`makeFlake`](../mkflake.md), taken from the `modulePaths` special
argument and made relative to `self.outPath`. Both path literals and strings
such as `"${self}/src"` work; the relative result carries no string context, so
the dev shell does not depend on the flake source. Entries that are directories
become `watch.dirs`, other paths become `watch.files`, and entries outside the
repository are ignored. Setting either option replaces its default.

## Outputs

- `file.".envrc"` holds the generated text.
- `git.ignore.patterns` gains `/.direnv` when the git module is present.
- The module does not add packages or CLI commands.

## Related

- [Reload the shell when Nix files change](../../tutorials/dev/direnv.md)
- [Configure direnv](../../guides/dev/direnv.md)
- [Why direnv watches the Nix tree](../../explanation/dev/direnv.md)
- [File module](file.md)
- [devModule](../dev-module.md)
