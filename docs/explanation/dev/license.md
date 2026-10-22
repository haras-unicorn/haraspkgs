# The license module

License generation can become a small document pipeline: fetch HTML, replace
annotated text, unwrap optional text, convert to Markdown, and format it. That
pipeline is useful for a documentation site, but it is a poor fit for the common
case of putting a standard license in a repository.

This module keeps the reusable part: an SPDX identifier, a source of plain text,
and a placeholder substitution map. The output is a plain license file. A
project with a custom license or a Markdown-specific rendering can point
`license.source` at its own file or keep that heavier work outside the dev
module.

## Plain text and SPDX data

`spdx-license-list-data` already publishes the licenses as plain text, so the
module does not need to parse HTML. That removes the HTML/CSS helpers and the
Pandoc conversion step, and it makes the source easy to override for a modified
license. The tradeoff is that placeholders are not classified; `license.attrs`
is an explicit key/value map, and the caller decides which substitutions apply.

## Fetched by nixpkgs, not hardcoded

The package comes from the nixpkgs input. The module stores no per-license hash
table, so updating nixpkgs is enough to get a newer SPDX dataset. A project that
needs a pinned or modified text can still use `license.source` without adding
another input.

## Related

- [License reference](../../reference/dev/license.md)
- [Generate a license](../../guides/dev/license.md)
- [The file module](file.md)
