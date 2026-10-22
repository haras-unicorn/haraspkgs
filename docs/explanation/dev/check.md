# The check module

The `check` module exists because "lint" and "test" are implementation details.
Nix flakes have one read-only aggregation point: `checks`. A linter, a type
checker, a unit-test runner, and a formatting check all fit there.

## Checks are derivations

Every `check.checks.<name>` becomes a derivation. The derivation copies the
repository source, runs the commands, and produces an output. That makes the
same definition usable from two places:

- `nix flake check` builds it for CI and release gates,
- `passthru.checks` exposes it to the dev shell and the self mirror,
- `dev check` runs the same command text directly in the checkout.

The shell name is part of the output name so checks from multiple shells do not
collide.

## Why the source is copied

A check must not modify the checkout. `nix flake check` also builds in a
sandbox, so `self.outPath` is copied into a writable directory before commands
run. Dev modules receive the downstream `self`, so the copy is the repository
that owns the check, not `haraspkgs`.

## Why there is no lint or test module

A lint module and a test module would each create their own action, their own
output, and their own way to run it. The `check` module avoids that split. Add
commands under a named check instead; the aggregation happens once in
`perSystem.checks`.

Framework-specific integrations can still exist later. They should register a
check, not a second top-level action.

## Related

- [Configure checks](../../guides/dev/check.md)
- [Check module reference](../../reference/dev/check.md)
