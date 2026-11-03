# The file module

The `file` module turns option definitions into shell-hook commands. It owns
`file.<path>` and contributes three things to the shell:

- a `packages` entry for every linked source file,
- a pre-hook command block for links and writes,
- generated `.gitignore` text for paths with `ignore = true`.

## Write only on change

The shell hook never rewrites a file that is already right. For each `text`
entry it builds the final content, compares it with the file on disk, and writes
only when they differ. Entering the shell, or direnv reloading it, leaves
up-to-date files untouched: no deleted files, no new modification times.

When the `format` module has enabled formatters, the content first goes through
`treefmt --stdin` and is held in memory, so formatting never writes to the
checkout. `format = false` skips that step and keeps the exact text. Symlinks
are replaced only when they point somewhere else, and `ensure` files are created
only when missing.

## Tree-wide formatting

Formatting the whole tree is not the hook's job; that is `dev format`. The file
module adds every `format = false` path to `format.excludes`, so `dev format`
does not reformat text that must stay exact, which the hook would only write
back.

## Generation order

Links run first, then writes. Both run before other shell hook commands because
the module uses `lib.mkBefore` on `shellHook`. Generated files reach later
linting and testing hooks in their final shape.

## The gitignore seam

`file` derives ignore patterns from its own file entries and writes the final
`.gitignore`. It never feeds the generated `.gitignore` back into its own
pattern source; the path is excluded while collecting patterns. The git module
supplies additional patterns and `github/gitignore` templates through
`file.".gitignore".text` without reading the generated file as input.

## Related

- [Generate files](../../guides/dev/file.md)
- [File module reference](../../reference/dev/file.md)
