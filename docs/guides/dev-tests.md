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

## Keep a test out of checks

Leave `flake` at its default `false` to keep the test in
`self.lib.devTests.<system>` without building it during `nix flake check`. Use
this for tests that need bwrap or another environment-specific tool.

## Run the tests

`nix flake check` builds every `dev-test-<name>` check. The check copies the
repository, runs the shell hook, and runs the commands inside the shell
environment. No `nix develop` is involved.
