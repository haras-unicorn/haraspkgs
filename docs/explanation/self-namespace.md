# The self namespace

`haraspkgs` uses one namespace, `self`, for everything a downstream flake
configures. The goal is that a repository never needs a second configuration
surface.

## One namespace

Options are spread across feature modules: `self.lib` in `src/lib/default.nix`,
`self.overlays` in `src/flake/overlays.nix`, `self.machines` in
`src/flake/machines.nix`, and the dev options in `src/flake/dev.nix`.
`makeFlake` imports the registered modules, so downstream configuration is
written under a single `self` attribute set.

## `self` and `flake`

Values use `selfLib.lib.selfSubmodule` and choose which surfaces they belong to:

- `self = true` includes the value in the `self` mirror.
- `flake = true` exports the value to the flake outputs.

Haraspkgs-provided flake modules and dev modules use
`self = false; flake = true;`. They are the provider's exported module sets, not
downstream `self` configuration. Downstream modules default to
`self = true; flake = false;`; set the opposite flags only when intentionally
exporting one.

The `self.lib` mirror makes downstream configuration reachable through a single
`selfLib` handle. Library helpers and per-system values live there too.

## Not every value is public

The flake output is the adoption surface. Keeping it small makes it predictable
and prevents internal refactors from becoming downstream breaking changes.
Downstream code should usually use `selfLib` inside modules, not read
`flake.lib`.

## Why not expose every option directly?

A single namespace keeps downstream configuration-only. Module sets are exported
as units through `flake.flakeModules` and `flake.devModules`, so users can
inspect or import a module without every internal option becoming public. Values
that need to be public opt in with `flake = true`; the rest stay internal to the
flake.

## Related

- [`makeFlake`](../reference/mkflake.md)
- [Introduction](../introduction.md)
