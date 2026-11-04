# File module

The `file` module is exported through `flake.devModules.file` and included in
the default group. It provides `file.<path>` options for repository files.

## Options

<!-- markdownlint-disable MD013 -->

| Field        | Type          | Default                            | Description                                                                                                  |
| ------------ | ------------- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `enable`     | bool          | set when text/source/ensure is set | Generate the file.                                                                                           |
| `text`       | lines or null | `null`                             | Keep the file at this content on shell entry.                                                                |
| `ensure`     | lines or null | `null`                             | Write this content only when the file is absent.                                                             |
| `source`     | path or null  | `null`                             | Link a generated copy of this source file.                                                                   |
| `partial`    | tag or null   | `null`                             | Merge `text` or `source` into the existing file instead of owning it. One of `text`, `json`, `toml`, `yaml`. |
| `format`     | bool          | `true`                             | Format the text before writing; `dev format` skips it when `false`.                                          |
| `executable` | bool          | `false`                            | Make the generated or linked file executable.                                                                |
| `ignore`     | bool          | `true` for `source` files          | Add the path to the generated `.gitignore`.                                                                  |

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

## Partial files

Set `partial.<format> = true;` to merge `text` or `source` into a file that is
also edited by hand, such as `Cargo.toml`. The tag picks the format and its
value is not used. `partial` needs exactly one of `text` and `source`, and it
cannot be combined with `ensure`. A partial `source` is merged and not linked,
so it is not added to `.gitignore`.

- `text`: on shell entry, append the text when the file does not contain it. The
  check fails when the file does not contain it.
- `json`, `toml` and `yaml`: on shell entry, merge the declared values into the
  file with `yq`. The check fails when the file differs from its merge.

A missing file is written from the declared text. The structured formats are
merged by [yq](https://github.com/mikefarah/yq) (`yq-go`) with
`yq eval-all '. as $item ireduce ({}; . * $item)'`: objects merge recursively,
the declared value wins on a conflict, and everything else follows the behavior
of that operator, including what happens to comments, key order and arrays. Read
the yq documentation for the exact rules. The merged text is then formatted like
any other generated text.

Run the shell, or `dev format`, to bring a partial file back in line with its
merge.

## Check

When the `check` module is present, a `file` check verifies the generated files.
It runs under `dev check` and `nix flake check`:

- A `text` file must equal its formatted text, and its executable bit must match
  `executable`.
- An `ensure` file must exist. Its content is not compared, because it is meant
  to be edited.
- A `partial` file must equal the merge of its current content and the declared
  text, formatted. The executable bit must match too.

Files with `ignore = true`, which includes linked `source` files, are skipped.
They are not tracked by git, so the repository source a check runs on does not
contain them. The check reports every failing file before it fails.

## Related

- [Generate files](../../guides/dev/file.md)
- [The file module](../../explanation/dev/file.md)
- [devModule](../dev-module.md)
