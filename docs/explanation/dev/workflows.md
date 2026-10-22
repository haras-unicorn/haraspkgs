# The workflows module

The `workflows` module exists because GitHub Actions files are repository
configuration. Like `.gitignore` and `.gitattributes`, they are written by the
shell hook; the committed files are mirrors for GitHub, not a second source of
truth.

## Rendering

The module collects `workflows.<name>` declarations, builds the base steps, and
renders each workflow with `lib.generators.toYAML`. The output is
JSON-compatible YAML. Each file is written through the `file` module, which
formats it at shell entry with the registered treefmt configuration. Formatting
stays at runtime, so evaluation does not build formatters for foreign systems.
The drift check repeats the Prettier step inside its build.

`installable` is a plain string with a default of `".#<name>"`. A downstream
flake can keep the default, point it at another package, or set it to `null` and
provide `steps` instead. The base steps stay the same: checkout, Nix, Cachix,
and the installable build.

## Drift

The formatted text is also used by a `workflows` passthru check. The check diffs
the committed `.github/workflows` files against the current declarations, so
`nix flake check` fails when a workflow was edited by hand or the declaration
changed without regenerating the file.

## Why not a flake module

Workflows must be written into the repository. That is exactly what the `file`
module and the shell hook already do, so the declaration lives with the dev
shell instead of adding another flake output and a second generation path.
