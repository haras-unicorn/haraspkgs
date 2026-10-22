# Format module

The `format` module is exported through `flake.devModules.format` and included
in the default group. It owns the treefmt configuration and exposes a formatter
and a format check.

## Options

<!-- markdownlint-disable MD013 -->

| Field                               | Type            | Default        | Description                               |
| ----------------------------------- | --------------- | -------------- | ----------------------------------------- |
| `format.treefmtPackage`             | package         | `pkgs.treefmt` | treefmt used by the formatter and check.  |
| `format.packages`                   | list of package | `[]`           | Additional packages available to treefmt. |
| `format.formatters.<name>.enable`   | bool            | `true`         | Whether treefmt runs this formatter.      |
| `format.formatters.<name>.packages` | list of package | `[]`           | Runtime packages for this formatter.      |
| `format.formatters.<name>.command`  | string          | required       | Formatter executable.                     |
| `format.formatters.<name>.options`  | list of strings | `[]`           | Arguments passed to the formatter.        |
| `format.formatters.<name>.includes` | list of strings | `[]`           | Files matched by the formatter.           |
| `format.formatters.<name>.excludes` | list of strings | `[]`           | Files excluded by the formatter.          |

<!-- markdownlint-enable MD013 -->

## Behavior

The module generates a treefmt TOML file from the enabled formatters. Every
formatter command and its packages are added to the runtime environment of both
actions.

- `formatter` runs treefmt normally, so it rewrites files.
- `format` check runs treefmt with `--fail-on-change`, so it fails when a file
  needs formatting.

The format check copies `self.outPath`; the formatter works in the checkout.

The `file` module uses the generated treefmt command to format generated files
from its shell hook. Formatting is therefore a runtime step; evaluation does not
build a formatter. Set `format = false` on a file entry to write the exact text.

Formatter configuration files are passed as store paths, not committed
repository files. The self shell supplies Prettier, Markdownlint, and
markdown-link-check configuration that way.

## Outputs

- `passthru.formatter` on the shell.
- `passthru.checks.format` on the shell.
- `perSystem.formatter` from the `default` shell.
- `perSystem.checks.<shell>-format`.

## Related

- [Configure formatting](../../guides/dev/format.md)
- [The format module](../../explanation/dev/format.md)
- [devModule](../dev-module.md)
