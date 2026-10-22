# Use the shell module

The shell module declares the stable shell fields. It is exported as
`flake.devModules.shell` and included in the default group.

## Define a dev module

```nix
{ self, ... }:
{
  self.devModules.rust = {
    value =
      { pkgs, ... }:
      {
        name = "rust-dev-shell";
        packages = [
          pkgs.cargo
          pkgs.rustc
        ];
        env.RUST_BACKTRACE = "1";
        shellHook = ''
          echo "rust shell"
        '';
      };
  };
}
```

Each entry is a submodule with `self`, `flake`, and `value`. Put the Nix module
in `value`. The common shell fields are `name`, `packages`, `buildInputs`,
`nativeBuildInputs`, `inputsFrom`, `shellHook`, and `env`.

## Select modules

All `self.devModules` entries with `self = true` are already available to every
dev shell. Add a shell to extend the environment:

```nix
{ self, ... }:
{
  self.devShells.rust = {
    value = {
      env.RUST_LOG = "info";
    };
  };
}
```

Lists are concatenated, `shellHook` commands are merged and rendered together,
and attributes merge by name. Conflicting definitions need normal module-system
handling, such as `lib.mkForce`.

## Extend the package set

`nixpkgs.overlays` are added after the flake overlays. The shell recreates
`_module.args.pkgs` from `nixpkgs.system`, `nixpkgs.config`, and the merged
overlay list, so a shell-local overlay is visible to every module that takes
`pkgs`:

```nix
{
  nixpkgs.overlays = [
    (final: _prev: {
      example-tool = final.hello;
    })
  ];
  packages = [ pkgs.example-tool ];
}
```

Files that every wrapped command should see belong in `bwrap.files`. Each value
has a `mode` and an optional `source` or `text`. The wrapper stages them outside
the checkout and exposes them through a read-only overlay lower layer for the
command.

## Hook language

`shellHook` is evaluated by bash. Nushell applications can be called from a
hook, but environment changes made inside the child process do not propagate
back to the shell. Use `env` for environment variables and bash for hook code.
See [the shell module reference](../../reference/dev/shell.md) for the command
shape.
