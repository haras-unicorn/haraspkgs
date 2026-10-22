# Your first check

The `check` module turns shell commands into derivations under
`perSystem.checks`. It is exported as `flake.devModules.check` and included in
the default dev module group.

## Add a check

Add a named check to the default shell. Each check gets its own runtime packages
and command list:

```nix
{
  self.devShells.default = {
    flake = true;
    value =
      { pkgs, ... }:
      {
        check.checks.lint = {
          packages = [ pkgs.markdownlint-cli ];
          commands = "markdownlint --ignore-path .gitignore .";
        };
      };
  };
}
```

## Run it

```bash
nix flake check
```

The check is exposed as `checks.<system>.default-lint`, because the shell is
named `default` and the check is named `lint`. `nix flake check` builds it in a
copy of `self.outPath`.

Next, read [how to configure checks](../../guides/dev/check.md) and the
[check reference](../../reference/dev/check.md).
