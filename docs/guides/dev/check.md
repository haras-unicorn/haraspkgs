# Configure checks

The `check` module is exported as `flake.devModules.check` and included in the
default group. It is the generic way to add read-only checks to a shell. Use
`format` for formatters and `check` for everything that should only pass or
fail.

## Add a check

```nix
{
  self.devShells.default = {
    flake = true;
    value =
      { pkgs, ... }:
      {
        check.checks.cspell = {
          packages = [ pkgs.cspell ];
          commands = "cspell lint . --no-progress";
        };
      };
  };
}
```

`check.checks.<name>.commands` uses the same command type as `shellHook`, so it
accepts a string, a list, or a structured command. All commands in one check run
in the same derivation, in order.

`check.packages` adds packages to every check in the shell. Put packages that
only one check needs in that check's `packages`.

## Run containers in a check

Set `podman.enable` on a check that needs containers, and list the images it
uses in `podman.images`:

```nix
check.checks.integration = {
  podman = {
    enable = true;
    images = [ pkgs.harasPackages.image-postgresql-18 ];
  };
  packages = [ pkgs.python3 ];
  commands = "python tests/integration.py";
};
```

The check derivation then starts a podman daemon in the build sandbox, loads the
images, and has `podman` on its `PATH`. Builds that run containers need the
`uid-range` system feature, which the check asks for itself; see
[Run containers in checks](../podman.md) for preparing the machine.

`dev check` runs the same commands in your checkout, where there is no sandbox
to start a daemon in. They use the daemon you already have, and the images are
loaded into it first. The daemon is whichever one `podman --remote` or `docker`
reaches, through their variables, configured connections or default sockets
(podman serves the Docker API socket too).

## Repository source

Dev modules get the flake `self`, `inputs`, and `specialArgs` as module
arguments. A check copies `self.outPath` into a writable directory before it
runs, so it can write temporary files without touching the checkout.

## Outputs

Each check becomes `passthru.checks.<name>` on the evaluated shell and
`perSystem.checks.<shell>-<name>` in the flake:

```text
checks.x86_64-linux.default-cspell
checks.x86_64-linux.default-markdownlint
```

A shell named `ci` produces `ci-cspell`, and so on. Checks from every shell are
projected; the shell name keeps them distinct.

Set `check.checks.<name>.enable = false` to keep a definition but skip its
derivation. This is useful when an integration provides a check that a
particular repository does not want.

The `cli` module turns the same entries into `dev check`, which runs the check
commands directly in the checkout. Use `nix flake check` for the derivations
built in a sandbox, and `dev check` while iterating.

## Unit tests

The generic module runs commands. It does not know how to run a specific test
framework. Haraspkgs wires `nix-unit` behind the same `self` namespace:

- `self.unitTests.<suite>` for system-agnostic suites.
- `perSystem.self.unitTests.<suite>` for suites that need `pkgs` or `system`.

Both are routed to `nix-unit`, which adds `checks.<system>.nix-unit`. Do not use
`flake.tests` or `perSystem.nix-unit.tests` directly.
