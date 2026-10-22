# The gitleaks module

The `gitleaks` module is an integration, not a second scanner. It builds one
configured wrapper and registers that wrapper with the generic git and check
modules.

## One configured command

All entry points call `dev-gitleaks`, which embeds the rendered TOML settings.
The pre-commit hook and the check never call `gitleaks` directly, so they cannot
drift from the shell command. The hook itself runs through the dev CLI as
`dev hook-pre-commit`.

When `gitleaks.settings` is empty, the wrapper omits `--config` and gitleaks
uses its built-in defaults. This keeps the module useful without a hand-written
rule set.

## Optional integration

The module does not assume that the git or check modules are loaded. It checks
whether their options exist and registers only the pieces that can be wired. A
shell that includes gitleaks without git still gets `dev-gitleaks`; it just does
not get the pre-commit hook.

When both are present, the module turns git on by default. The pre-commit hook
scans staged changes, while the check scans the copied repository in the
sandbox. The two scopes are intentionally different: hooks stay fast, and the
check sees everything.

## Related

- [Scan for secrets](../../guides/dev/gitleaks.md)
- [Gitleaks module reference](../../reference/dev/gitleaks.md)
- [The git module](git.md)
- [The check module](check.md)
