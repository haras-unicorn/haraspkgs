# The code of conduct module

Contributor Covenant is a single Markdown file with a stable URL per version.
The module therefore does only three things: resolve a version to a URL, fetch
the file with a fixed-output hash, and write it through the `file` module. The
file module formats it at shell entry when the `format` module is active.

## Version and hash

The URL is derived from `version` by replacing dots with slashes, but Nix cannot
derive a fixed-output hash from a URL. `hash` stays an explicit option so the
module works when the version is overridden. The default pair points at
Contributor Covenant 3.0.

Keeping the hash next to the version makes the fetch reproducible without adding
a flake input for a file that changes only when the policy version changes.
`source` is the escape hatch for a local or modified policy.

## Small on purpose

This module is not a general document generator. The repository owns the policy
text, and the module owns placement and fetching. That keeps the default path
small and makes the file easy to replace with a project-specific source.

## Related

- [Code of conduct reference](../../reference/dev/code-of-conduct.md)
- [Add a code of conduct](../../guides/dev/code-of-conduct.md)
- [The file module](file.md)
