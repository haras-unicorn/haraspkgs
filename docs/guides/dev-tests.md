# Test a dev shell

Declare a test under `self.devTests` in `tests/dev/<module>.nix`. The test
evaluates a list of dev shell modules, then runs commands in the resulting
shell. Prefer assertions about files, output, and exit codes over evaluated
config attrs.

## Add a test

```nix
{ ... }:
{
  self.devTests.example = {
    flake = true;

    value = {
      modules = [
        { pkgs, ... }: {
          packages = [ pkgs.hello ];
        }
      ];
      commands = [ "hello" ];
    };
  };
}
```

The modules are deferred, so they receive `pkgs` when a system is evaluated.
They are combined with the same default dev modules and shell overlay as
`self.devShells`.

## Reuse a dev module

A downstream dev module is available at `self.lib.devModules.<name>`:

```nix
self.devTests.example = {
  flake = true;

  value = {
    modules = [ self.lib.devModules.example ];
    commands = [ "test -f .generated.txt" ];
  };
};
```

A declared shell module can be reused with `config.self.devShells.<name>.value`.

## Test a shell that runs containers

A test whose commands need a podman daemon, such as a shell with a
`check.checks.<name>.podman` check that the test runs through `dev check`, sets
`podman.enable`:

```nix
self.devTests.check-podman = {
  flake = true;

  value = {
    podman.enable = true;
    modules = [ self.lib.devModules.example ];
    commands = [ "dev check" ];
  };
};
```

This only makes the build require the `uid-range` system feature. The daemon is
started by the command that needs it, which `dev check` does for checks with
`podman.enable`.

## Keep a test out of checks

Leave `flake` at its default `false` to keep the test in
`self.lib.<system>.devTests` without building it during `nix flake check`. Use
this for tests that need bwrap or another environment-specific tool.

## Run the tests

`nix flake check` builds every `dev-test-<name>` check. The check copies the
repository, runs the shell hook, and runs the commands inside the shell
environment. No `nix develop` is involved.
