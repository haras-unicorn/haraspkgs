# Why direnv watches the Nix tree

Every Nix file in a haraspkgs repository is a module imported through
`import-tree`. The flake is the only file that names them, so direnv's
`use flake` has no way to know they exist.

## What `use flake` watches

`use flake` watches `flake.nix` and `flake.lock`, nothing else. Edit a module
under `src/` and direnv sees no change. nix-direnv makes it worse: it caches the
evaluated shell and rebuilds the cache only when a file in direnv's watch list
is newer than the cache. A stale shell stays stale.

## Watching directories

`watch_dir` adds a directory recursively, so a changed, added or removed file
inside reloads the shell on the next prompt. The module turns
`direnv.watch.dirs` into `watch_dir` lines. That alone is not enough, as the
next sections explain.

## Why the watches appear twice

nix-direnv decides whether to rebuild its cache while `use flake` runs, by
looking at the watches registered so far in that run. direnv clears the watches
of the previous load before it evaluates `.envrc`, so a `watch_dir` written only
after `use flake` makes direnv reload but is invisible to nix-direnv, which then
reuses the stale cache. The module therefore registers the watches before
`use flake` as well. An edited file is newer than the cache, and an added or
removed file changes the modification time of its directory, so the shell is
rebuilt in all three cases.

## Where the paths come from

The flake names its module locations once, in `makeFlake`'s `modules`.
`makeFlake` hands those paths to every module as the `modulePaths` special
argument, and the module watches them by default: directories with `watch_dir`,
files with `watch_file`. The paths arrive as store paths, so the module strips
the flake's `self.outPath` prefix to get the repository-relative form direnv
needs, and ignores anything outside the repository. Watching the whole
repository instead would reload on every source edit, which is why the default
is the module tree and not `.`.

## Why the watches are registered again after `use flake`

direnv records the modification time of every watched path, in whole seconds,
the moment the watch is registered, and reloads when a later check finds a
different time. Registering a path again replaces its recorded time.

The shell hook runs inside `use flake`, and anything it runs can modify a
watched directory: a wrapped formatter may stage files in the checkout, for
example. If the watches were only registered first, that change would land after
the recorded time and the next prompt would reload, run the hook again, and
change the directory again, on every prompt. Registering the watches again after
`use flake` records the state the hook leaves behind, so only later edits count.

## How it fits with the file module

A rebuilt shell runs its shell hook again, and the `file` module syncs the
generated files there, writing only what changed. That closes the loop: edit a
Nix file, direnv reloads, `.gitignore`, the workflows and the other generated
files are current again. Nothing outdated waits for a manual command, and
unchanged files are not touched.

## A generated `.envrc`

`.envrc` is declared in Nix like the other repository files, so its watch lists
live next to the rest of the shell configuration. direnv has to read it before
the shell exists, so the first copy must be committed, as with the other
mirrors. When the declaration changes, the hook rewrites the file and direnv
blocks it until `direnv allow`; that prompt is direnv's own security check and
is left in place.

Without nix-direnv, direnv's built-in `use flake` evaluates the shell on every
load, so the watches alone are enough.

## Related

- [Reload the shell when Nix files change](../../tutorials/dev/direnv.md)
- [Configure direnv](../../guides/dev/direnv.md)
- [Direnv reference](../../reference/dev/direnv.md)
- [The file module](file.md)
