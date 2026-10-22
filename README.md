# haraspkgs

Common Nix library and packages I reuse across my `haras-unicorn` repositories.

> **Status:** `v1.0.0`.

## Adopt

```nix
{
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

`nixpkgs` is required. `flake-parts` and `import-tree` are provided by
`haraspkgs`, so downstream flakes do not declare them. Pin a release tag for
reproducible builds, or use the branch URL to track `main`.

## Development

Enter the dev shell with `nix develop` or `direnv allow`. Every `.nix` file is a
flake-parts module: source lives in `src/`, tests in `tests/`, and docs in
`docs/`.

Common commands:

```sh
dev format
dev check
dev docs
dev check-links
nix flake check
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the short version and
[AGENTS.md](AGENTS.md) for the repository conventions.

## Documentation

The docs are the primary adoption resource. Start at
[docs/introduction.md](docs/introduction.md).

The documentation follows Diátaxis: tutorials, how-to guides, reference, and
explanation.
