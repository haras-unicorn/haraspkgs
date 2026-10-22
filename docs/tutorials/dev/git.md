# Add git hooks

The `git` module writes ignore patterns and attributes through the `file`
module, and wraps `git` so the configured hooks run without editing
`.git/config`.

## Configure the shell

```nix
{
  self.devShells.default.value = {
    git = {
      enable = true;
      ignore = {
        templates = [ "Nix" ];
        patterns = "docs/book";
      };
      attributes = "* text=auto eol=lf";
      hooks.pre-commit.commands = "echo checking";
    };
  };
}
```

## Enter the shell

```console
$ nix develop
> writing
write .gitattributes
write .gitignore
$ git config --get core.hooksPath
/nix/store/...-haraspkgs-git-hooks
```

The generated `pre-commit` hook runs `dev hook-pre-commit`, which changes to the
flake root and runs `echo checking`. The hook lives in the Nix store; the
wrapped `git` command points at it with `core.hooksPath` environment
configuration. The repository's `.git/config` and `.git/hooks` are not modified.

Add `packages` to the hook when its commands need tools. The wrapper runs `git`
through `bwrap` with the project root mounted read-write.

Next, read [how to configure git](../../guides/dev/git.md) and the
[git reference](../../reference/dev/git.md).
