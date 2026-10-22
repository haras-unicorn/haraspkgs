# Shell module

The base shell module is exported as `flake.devModules.shell` and included in
the default dev module group. It declares the fields shared by every shell.

## Fields

<!-- markdownlint-disable MD013 -->

| Field               | Type            | Default                 | Description                                   |
| ------------------- | --------------- | ----------------------- | --------------------------------------------- |
| `name`              | string          | `"haraspkgs-dev-shell"` | Derivation name used for the shell.           |
| `packages`          | list of package | `[]`                    | Packages added to the shell and its `PATH`.   |
| `buildInputs`       | list of package | `[]`                    | Inputs added to the shell environment.        |
| `nativeBuildInputs` | list of package | `[]`                    | Native inputs added to the shell environment. |
| `inputsFrom`        | list of package | `[]`                    | Packages whose build inputs are inherited.    |
| `shellHook`         | commands        | `[]`                    | Commands run when the shell starts.           |
| `env`               | attrs           | `{}`                    | Environment variables exported by the shell.  |
| `passthru`          | attrs           | `{}`                    | Derivation passthru attributes.               |
| `nixpkgs.system`    | string          | shell system            | System used to recreate the package set.      |
| `nixpkgs.config`    | attrs           | shell config            | Nixpkgs configuration.                        |
| `nixpkgs.overlays`  | list of overlay | `[]`                    | Extra overlays, applied after the flake ones. |
| `bwrap.files`       | attrs           | `{}`                    | Files bound into every wrapped command.       |

<!-- markdownlint-enable MD013 -->

## Package set

`_module.args.pkgs` is recreated with
`import shellPkgs.path { inherit (config.nixpkgs) system config overlays; }`.
The base overlays are prepended with `lib.mkBefore`, user overlays are merged in
the middle, and the global-bwrap overlay is appended with `lib.mkAfter`. The
global overlay wraps `harasPackages.makeBubblewrapWrapper` so every wrapper
receives `config.bwrap.files`; it stays lazy and only reads those files when a
wrapper is called.

Each `bwrap.files.<path>` entry is a submodule with `mode` (`"ro"`, the
default), and an optional `source` or `text`. `source` and `text` are mutually
exclusive, and `mode = "rw"` cannot use them.

## Commands

`shellHook` uses the `commands` type. It accepts a string, a list of strings and
attrsets, or a single attrset. Strings are shorthand for `{ text = "..."; }`.
Each command also supports `prompt`, `depth`, and `header`. The evaluator merges
all definitions into one list and renders it with `concatCommands` before
passing the result to `pkgs.mkShell`.

`shellHook` is evaluated by bash. Nushell applications can be called from a
hook, but environment changes made inside the child process do not propagate
back to the shell. Use `env` for environment variables and bash for hook code.

## Related

- [Use the shell module](../../guides/dev/shell.md)
- [The shell module](../../explanation/dev/shell.md)
- [devModule](../dev-module.md)
