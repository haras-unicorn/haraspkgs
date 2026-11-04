# Configure direnv

The `direnv` module is exported as `flake.devModules.direnv` and included in the
default group. It generates `.envrc` through the [file module](file.md) and adds
`/.direnv` to the generated `.gitignore` when the git module is present.

## Watch your Nix files

`use flake` only watches `flake.nix` and `flake.lock`. The module watches what
you passed to `makeFlake` as `modules`, so enabling it is enough:

```nix
{
  direnv.enable = true;
}
```

With `modules = [ ./src ./tests ]`, the generated `.envrc` gets `watch_dir src`
and `watch_dir tests`. Directories are watched recursively, so adding, removing
or editing any file inside reloads the shell. Files in `modules` get
`watch_file` instead. Only paths inside the repository count.

Set `watch.dirs` or `watch.files` to replace those defaults, for example to
watch a file outside your modules:

```nix
{
  direnv.watch.files = [ "VERSION.txt" ];
}
```

The replacement is complete: list the module directories again if you still want
them watched.

## Load a `.env` file or change `use flake`

`extra` is added before `use flake`, and `useFlake` holds the arguments of
`use flake`:

```nix
{
  direnv = {
    extra = "dotenv_if_exists .env";
    useFlake = [
      "."
      "--show-trace"
    ];
  };
}
```

## Approve changes

The shell hook rewrites `.envrc` only when its content changes. direnv blocks a
changed `.envrc` until you run `direnv allow`. Commit the file: direnv reads it
before the shell exists, so the first copy cannot come from the shell.

See the [direnv reference](../../reference/dev/direnv.md) for the option shape.
