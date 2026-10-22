# The file module

The `file` module turns option definitions into shell-hook commands. It owns
`file.<path>` and contributes three things to the shell:

- a `packages` entry for every linked source file,
- a pre-hook command block for links and writes,
- generated `.gitignore` text for paths with `ignore = true`.

Text and ensured files are written raw. When the `format` module has enabled
formatters, the file module's shell hook runs treefmt on the paths written with
`format = true` after the write block. `format = false` opts a path out.

## Generation order

Links run first, then writes, then formatting. All three run before other shell
hook commands because the module uses `lib.mkBefore` on `shellHook`. Generated
files reach later linting and testing hooks in their final shape.

## The gitignore seam

`file` derives ignore patterns from its own file entries and writes the final
`.gitignore`. It never feeds the generated `.gitignore` back into its own
pattern source; the path is excluded while collecting patterns. The git module
supplies additional patterns and `github/gitignore` templates through
`file.".gitignore".text` without reading the generated file as input.

## Related

- [Generate files](../../guides/dev/file.md)
- [File module reference](../../reference/dev/file.md)
