# Generate repository files

The `file` module creates files when a shell starts. This tutorial adds a
generated `.envrc` and a file that is created only once.

## Add file options

Put the options in a dev module or directly in a shell:

```nix
{
  self.devModules.files = {
    value = {
      file.".envrc".text = "use flake";
      file.".keep".ensure = "created once";
    };
  };
}
```

`text` is rewritten every time the shell starts. `ensure` leaves an existing
file alone, which is useful for local state that should not be overwritten.
Generated text is formatted by the matching formatter when the shell starts and
the `format` module is active; set `format = false` to keep the exact text.

## Enter the shell

```console
$ nix develop
> writing
write .envrc
ensure .keep
> formatting generated files
$ cat .envrc
use flake
```

The generated shell hook reports each file it creates. If a file has
`source = ./tool.sh`, it is linked from the store instead; source files are
added to `.gitignore` by default.

Next, read [the file module guide](../../guides/dev/file.md) and the
[file reference](../../reference/dev/file.md).
