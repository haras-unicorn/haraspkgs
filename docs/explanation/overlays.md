# Why overlays are a graph

`self.overlays` looks larger than a list of overlay functions because a
repository usually has packages that build on each other. The base module
represents that as a named dependency graph and then composes it into the
package set.

## Names and dependencies

Each overlay has a name under `self.overlays.overlays` and an optional `deps`
list. The base module defines the overlay options, so the submodule defaults are
available even during the bootstrap pass. Dependencies are exact names or
`/regex/` patterns. Selected overlays are expanded transitively and
topologically sorted before composition. A missing dependency or a cycle fails
evaluation instead of producing a package set with a silently missing attribute.

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

The base module exposes the composed namespace overlay as
`self.lib.overlays.nixpkgs`. That keeps `perSystem` modules, dev shells, and the
exported packages on the same package set. The cost is that consumers use
`pkgs.harasPackages.foo`; the graph is not a package manager and does not
resolve versions.

## The shell overlay

The `shell` overlay provides `pkgs.harasPackages.makeBubblewrapWrapper`. It is a
normal overlay with `flake = true` and the default `self = true` for now, so it
appears in `self.lib.overlays.overlays` and the flake's own package set.

`makeBubblewrapWrapper` runs a package through `bwrap` with a default sandbox
for a Nix machine. The base comes from `self.lib.bwrap`: the local profile
unshares all namespaces and omits network configuration, while the network
profile keeps the host network and provides the related `/etc` files. The store,
system paths, and home configuration are available read-only, while the project
root is writable so development commands can update the checkout. Callers choose
the network profile with `network = true` and can add bind overrides for
specific paths.

`src/overlays/dev.nix` also extends the evaluated shell `pkgs` with the same
overlay before it calls `evalModules` and `mkShell`, so dev shells keep the
helper even when they recreate their package set.

## Related

- [Overlays reference](../reference/overlays.md)
- [Add an overlay](../guides/overlays.md)
