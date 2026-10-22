# The format module

The `format` module separates the two things a formatter does: changing files
and checking that files are already formatted.

## One treefmt configuration

All formatters are described as data: command, arguments, and include/exclude
globs. The module renders one treefmt TOML file. Both actions use that same
file, so `nix fmt` and `nix flake check` cannot disagree about which formatter
handles which file.

## Mutating and read-only actions

`passthru.formatter` runs treefmt normally. It rewrites files and is meant for
`nix fmt`; `dev format` runs the same treefmt configuration directly.

`passthru.checks.format` runs treefmt with `--fail-on-change`. It is meant for
`nix flake check`. Using treefmt means a formatter does not need a separate
check mode; treefmt detects whether the formatter changed anything.

## Generated files

Some files are not edited by hand: workflows, code of conduct files, licenses,
and other module-owned text. The `file` module writes them raw; entries with
`format = true` are formatted at shell entry by the same treefmt configuration,
so the committed files are formatter-clean without building a formatter during
evaluation. Set `format = false` to keep exact text (the license and git files
do).

## Formatter selection

`perSystem.formatter` is a single derivation, so it is taken from the `default`
dev shell. Checks, by contrast, are collected from every shell and prefixed with
the shell name.

## Why the check copies the source

The formatter runs in the user's checkout. The check runs in a sandbox, so it
copies `self.outPath` into a writable directory first. That keeps `nix fmt` and
`nix flake check` on the same configuration without letting the check modify the
checkout.

## Related

- [Configure formatting](../../guides/dev/format.md)
- [Format module reference](../../reference/dev/format.md)
