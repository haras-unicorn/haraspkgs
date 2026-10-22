# Your first downstream flake

This tutorial takes an empty repository to a working `haraspkgs` flake.

## 1. Create the flake

```nix
{
  description = "My project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    haraspkgs.url = "github:haras-unicorn/haraspkgs";
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

`makeFlake` registers the `self.*` options. Directory entries in `modules` are
imported with `import-tree`; file paths and other modules are passed through
unchanged.

## 2. Add a module

Create `src/default.nix`:

```nix
{
  self.overlays.overlays.hello = {
    flake = true;
    value = final: _prev: {
      hello = final.writeShellApplication {
        name = "hello";
        text = "echo hello";
      };
    };
  };
}
```

The `value` attribute holds the overlay function and `flake = true` exports it
to the flake outputs. `haraspkgs` composes it with the other overlays and
applies the default `harasPackages` namespace.

## 3. Check it

```console
nix flake check
nix build .#hello
./result/bin/hello
```

The overlay is namespaced, so the package is available as
`pkgs.harasPackages.hello` inside modules and as a flake package.

## Next steps

- [Add an overlay](../guides/overlays.md)
- [Add a dev shell](../guides/dev-shells.md)
- [Read the `makeFlake` reference](../reference/mkflake.md)
