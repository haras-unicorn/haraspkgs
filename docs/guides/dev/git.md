# Configure git

The `git` module is exported as `flake.devModules.git` and included in the
default group. It writes repository ignore patterns and attributes through the
`file` module, wraps `git` with `bwrap`, and points hooks at a generated store
path without editing `.git/config`. Repository configuration should live in the
dev shell; see [the git explanation](../../explanation/dev/git.md).

## Enable git

```nix
{
  self.devShells.default = {
    flake = true;
    value = {
      git = {
        enable = true;
        ignore.patterns = ''
          result
          result-*
          .direnv
        '';
        attributes = "*.nix text";
      };
    };
  };
}
```

The patterns are written before templates and merged with patterns from the
`file` module. The attributes are written to `.gitattributes`.

## Add ignore templates

The `github-gitignore` flake input points at `github/gitignore`. Select
templates by file name without the `.gitignore` suffix:

```nix
{
  git.ignore.templates = [
    "Nix"
    "Python"
  ];
}
```

Each template is read from the input, so updating the input updates the
generated `.gitignore`. Downstream flakes can add their own `github-gitignore`
input to override the version; otherwise the module uses haraspkgs' input.

## Add a hook

```nix
{
  self.devShells.default.value =
    { pkgs, ... }:
    {
      git.hooks.pre-commit = {
        packages = [ pkgs.deadnix ];
        commands = "deadnix --fail .";
      };
    };
}
```

Every hook is exposed as `dev hook-<name>` and installed in a generated store
directory. The `git` wrapper sets `core.hooksPath` through the
`GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_0`/`GIT_CONFIG_VALUE_0` environment
variables, so Git uses those hooks without a write to `.git/config` or
`.git/hooks`. The hook's `packages` are added to that CLI subcommand. Set
`git.hooks.<name>.enable = false` to keep a hook definition but stop generating
it.

The wrapped `git` runs through `bwrap` with the project root mounted read-write
so hooks and normal Git commands can update the checkout.

## Related

- [Git module reference](../../reference/dev/git.md)
- [The git module](../../explanation/dev/git.md)
- [Generate files](file.md)
- [Scan for secrets](gitleaks.md)
