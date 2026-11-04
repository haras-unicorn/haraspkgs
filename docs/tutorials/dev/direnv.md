# Reload the shell when Nix files change

The `direnv` module generates `.envrc` so direnv reloads your dev shell when any
of your Nix files change, not only `flake.nix` and `flake.lock`.

## Enable the module

```nix
{
  self.devShells.default.value = {
    direnv.enable = true;
  };
}
```

The module watches the paths you passed to `makeFlake`. This tutorial assumes
`modules = [ ./src ]`.

## Enter the shell once

```console
$ nix develop
> writing
write .envrc
$ cat .envrc
use flake . --show-trace
watch_dir src
```

Commit `.envrc`. direnv has to find it before the shell exists, and the module
keeps it in sync from then on. The first time, and after every change to it,
direnv blocks the file until you approve it:

```bash
direnv allow
```

## Edit a Nix file

Change any file under `src/` and the next prompt reloads the shell. The shell
hook runs again, so generated files such as `.gitignore` and the workflows are
brought up to date without a manual step.

Next, read [how to configure direnv](../../guides/dev/direnv.md) and the
[direnv reference](../../reference/dev/direnv.md).
