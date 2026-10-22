# Why overlays are a graph

`self.overlays` looks larger than a list of overlay functions because a
repository usually has packages that build on each other. The module represents
that as a named dependency graph and then composes it into the package set.

## Names and dependencies

Each overlay has a name under `self.overlays.overlays` and an optional `deps`
list. Dependencies are exact names or `/regex/` patterns. Selected overlays are
expanded transitively and topologically sorted before composition. A missing
dependency or a cycle fails evaluation instead of producing a package set with a
silently missing attribute.

## The namespace

Overlay values write un-namespaced attributes (`foo`, not `harasPackages.foo`).
After composing, `haraspkgs` wraps the result in the configured namespace. That
gives one predictable attribute set (`pkgs.harasPackages`) and avoids scattering
project-specific packages across the top-level package set. It also lets the
same composed result become `packages` and `apps` without repeating the overlay
order.

## Export subsets

`self` and `flake` mark where an overlay is used. `self = true` includes it in
the `self` package set; `flake = true` includes it in `flake.overlays` and the
derived flake packages and apps. Dependencies are always included, even when the
dependency is not exported itself, because an overlay cannot run without them.

## One package set

The module puts the composed namespace overlay into `self.nixpkgs.overlays`.
That keeps `perSystem` modules, dev shells, and the exported packages on the
same package set. The cost is that consumers use `pkgs.harasPackages.foo`; the
graph is not a package manager and does not resolve versions.

## Shell-only overlays

Not every overlay belongs in the package set used to evaluate the flake. The
`shell` overlay is an example: it exists so every evaluated dev shell can use
`pkgs.harasPackages.makeBubblewrapWrapper`, but adding that helper to
`self.nixpkgs.overlays` would make it available to package and NixOS modules
that do not need it.

`makeBubblewrapWrapper` runs a package through `bwrap` with a default sandbox
for a Nix machine: the store, system configuration, and home configuration are
available read-only, while the project root is writable so development commands
can update the checkout. Callers can add bind overrides for specific paths. This
is deliberately a shell concern, not a package-builder concern.

`src/overlays/dev.nix` therefore extends the shell `pkgs` with the shell overlay
before it calls `evalModules` and `mkShell`. The overlay is still registered and
composed like any other overlay, so its dependencies and export flags remain
visible. `self = false` keeps it out of the flake's own `pkgs`; the dev-shell
evaluator opts into it explicitly.

## Related

- [Overlays reference](../reference/overlays.md)
- [Add an overlay](../guides/overlays.md)
