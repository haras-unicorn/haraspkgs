# File module

The `file` module is exported through `flake.devModules.file` and included in
the default group. It provides `file.<path>` options for repository files.

## Options

<!-- markdownlint-disable MD013 -->

| Field        | Type          | Default                            | Description                                                         |
| ------------ | ------------- | ---------------------------------- | ------------------------------------------------------------------- |
| `enable`     | bool          | set when text/source/ensure is set | Generate the file.                                                  |
| `text`       | lines or null | `null`                             | Keep the file at this content on shell entry.                       |
| `ensure`     | lines or null | `null`                             | Write this content only when the file is absent.                    |
| `source`     | path or null  | `null`                             | Link a generated copy of this source file.                          |
| `format`     | bool          | `true`                             | Format the text before writing; `dev format` skips it when `false`. |
| `executable` | bool          | `false`                            | Make the generated or linked file executable.                       |
| `ignore`     | bool          | `true` for `source` files          | Add the path to the generated `.gitignore`.                         |

<!-- markdownlint-enable MD013 -->

## Behavior

Text and ensured files are written from the bash shell hook before other hook
commands. When the `format` module is present and has enabled formatters, the
text is first formatted in memory with `treefmt --stdin`. A `text` file is
written only when the result differs from the file on disk, and an `ensure` file
only when it is missing. The hook prints `write <path>` for each file it
changes. Set `format = false` to keep the exact text; the file module then adds
the path to `format.excludes`, so `dev format` leaves it alone. Source files are
copied into the store and symlinked into the repository when the link is missing
or points elsewhere; `executable` applies to that store file.

Generated ignore patterns are prepended to `file.".gitignore".text`; an explicit
`.gitignore` text definition is appended after them. The generated `.gitignore`
is excluded from its own pattern source to avoid a module-option cycle.

## Related

- [Generate files](../../guides/dev/file.md)
- [The file module](../../explanation/dev/file.md)
- [devModule](../dev-module.md)
