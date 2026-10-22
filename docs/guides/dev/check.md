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
