# EditorConfig as formatting policy

EditorConfig is often treated as an editor preference file. Here it is the
repository's root formatting policy. The dev module owns the structured values,
and the bwrap-delivered `.editorconfig` is the file that editors and
EditorConfig-aware tools read while a wrapped command runs.

## One source of truth

Formatters in this repository are driven by `format.formatters`, which writes a
treefmt configuration. Several of those tools also understand EditorConfig. If
the two sources disagree, the result depends on which tool ran last. Keeping the
policy in `editorconfig.settings` lets formatter modules read or mirror the same
values instead of inventing a second set.

The module always writes `root = true` because it describes the repository, not
a subdirectory fragment that should inherit from a parent checkout. That also
makes the generated file safe to use outside the dev shell.

## Delivered, not hand-maintained

The file lives only for the duration of a wrapped command. The wrapper stages it
outside the checkout and exposes it through a read-only overlay lower layer
while the tool runs. Changing the policy means changing the settings; there is
no committed copy to keep in sync and no repository file to ignore.

## Related

- [EditorConfig reference](../../reference/dev/editorconfig.md)
- [Configure EditorConfig](../../guides/dev/editorconfig.md)
- [The file module](file.md)
