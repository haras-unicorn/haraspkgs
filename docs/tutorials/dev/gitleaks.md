# Scan for secrets

The `gitleaks` module adds a configured `dev-gitleaks` command, a pre-commit
hook, and a check. This tutorial enables it with one rule.

## Enable gitleaks

```nix
{
  self.devShells.default.value = {
    gitleaks = {
      enable = true;
      settings.rules = [
        {
          id = "example-token";
          description = "Example token";
          regex = "EXAMPLE_[A-Z0-9]{16}";
        }
      ];
    };
  };
}
```

## Try it

```console
$ nix develop
$ dev-gitleaks dir .
$ git commit -m "test"
> dev-gitleaks git --staged --pre-commit .
...
```

The pre-commit hook scans staged changes. The `gitleaks` check scans the whole
repository when `nix flake check` or `dev check` runs.

Next, read [how to configure gitleaks](../../guides/dev/gitleaks.md) and the
[gitleaks reference](../../reference/dev/gitleaks.md).
