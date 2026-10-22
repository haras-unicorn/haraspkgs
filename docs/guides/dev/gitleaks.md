# Scan for secrets

The `gitleaks` module is exported as `flake.devModules.gitleaks` and included in
the default group. It adds a `dev-gitleaks` command and wires the scanner into
git hooks and checks.

## Enable gitleaks

```nix
{
  self.devShells.default.value = {
    gitleaks.enable = true;
  };
}
```

The module adds `dev-gitleaks` to the shell. With the git module present it also
enables git and adds a `pre-commit` hook that scans staged changes. With the
check module present it adds a `gitleaks` check that scans the copied
repository.

## Configure rules

```nix
{
  gitleaks.settings = {
    title = "example";
    rules = [
      {
        id = "example-token";
        description = "Example token";
        regex = "EXAMPLE_[A-Z0-9]{16}";
      }
    ];
  };
}
```

Settings are rendered to a TOML file and passed with `--config`. Leave
`settings` empty to use gitleaks' default configuration.

## Run it

```bash
dev-gitleaks dir .
dev-gitleaks git --staged .
dev check
```

`dev-gitleaks` is the configured wrapper, so it always uses the module's
settings. The pre-commit hook runs the staged scan automatically.

To keep the integration but skip one part, set
`git.hooks.pre-commit.enable = false` or `check.checks.gitleaks.enable = false`.

## Related

- [Gitleaks module reference](../../reference/dev/gitleaks.md)
- [Configure git](git.md)
- [Configure checks](check.md)
