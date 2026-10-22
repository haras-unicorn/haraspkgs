# Gitleaks module

The `gitleaks` module is exported through `flake.devModules.gitleaks` and
included in the default dev module group. It wraps the secret scanner in a
`dev-gitleaks` command and integrates it with the `git` and `check` modules.

## Options

<!-- markdownlint-disable MD013 -->

| Field                 | Type       | Default         | Description                                      |
| --------------------- | ---------- | --------------- | ------------------------------------------------ |
| `gitleaks.enable`     | bool       | `false`         | Enable gitleaks.                                 |
| `gitleaks.package`    | package    | `pkgs.gitleaks` | Gitleaks package run by `dev-gitleaks`.          |
| `gitleaks.gitPackage` | package    | `pkgs.git`      | Git package available to the hook and the check. |
| `gitleaks.settings`   | TOML attrs | `{}`            | Configuration written to `gitleaks.toml`.        |

<!-- markdownlint-enable MD013 -->

## Behavior

When enabled, the module adds a `dev-gitleaks` wrapper to `packages`. The
wrapper passes `--config` only when `gitleaks.settings` is not empty; otherwise
gitleaks uses its default configuration.

If the `git` module is present, the module enables git by default and adds a
`pre-commit` hook that runs `dev-gitleaks git --staged --pre-commit .`. The hook
is exposed through the CLI as `dev hook-pre-commit`.

If the `check` module is present, the module adds a `gitleaks` check that runs
`dev-gitleaks dir .` in the copied repository source. The check is exposed as
`perSystem.checks.<shell>-gitleaks` and can be disabled with
`check.checks.gitleaks.enable = false`.

## Outputs

- `dev-gitleaks` in `packages`.
- `git.hooks.pre-commit` when the git module is present.
- `check.checks.gitleaks` when the check module is present.

## Related

- [Scan for secrets](../../guides/dev/gitleaks.md)
- [The gitleaks module](../../explanation/dev/gitleaks.md)
- [Git module](git.md)
- [Check module](check.md)
