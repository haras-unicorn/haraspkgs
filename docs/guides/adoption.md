# Adopt haraspkgs

This is the shortest path to adding `haraspkgs` to an existing flake.

## Minimal downstream flake

```nix
{
  description = "My project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    haraspkgs.url = "github:haras-unicorn/haraspkgs/v1.0.0";
    haraspkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { haraspkgs, ... }@inputs:
    haraspkgs.lib.makeFlake {
      inherit inputs;
      modules = [ ./src ];
    };
}
```

`nixpkgs` is required because the shared modules import it. Following it into
`haraspkgs` keeps both flakes on the same package set. Pin a release tag for
reproducible builds; use `github:haras-unicorn/haraspkgs` to track `main`.

A downstream flake does not need `flake-parts` or `import-tree` inputs.
`makeFlake` uses the copies from the `haraspkgs` closure.

## Create the modules

`modules` is a normal module list. Directory entries are imported with
`import-tree`; file paths, functions, and attribute sets are passed through
unchanged. A downstream flake can keep tests or tooling in separate directories
by adding them to the same list.

## Forward extra arguments

`inputs` becomes the downstream flake inputs passed to flake-parts. Every other
argument, such as `specialArgs`, is forwarded unchanged:

```nix
haraspkgs.lib.makeFlake {
  inherit inputs;
  modules = [ ./src ];
  specialArgs = {
    inherit (inputs) nixpkgs;
  };
}
```

## Add features

Add modules under `src/`. Each feature has a focused guide:

- [Add an overlay](overlays.md)
- [Add a dev shell](dev-shells.md)
- [Add a machine](machines.md)

## Verify

```console
nix flake check
```
