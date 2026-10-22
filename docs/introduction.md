# Introduction

`haraspkgs` is a personal Nix library and package collection shared by the
`haras-unicorn` repositories. It is built around flake-parts modules, a single
`self.*` namespace, and a small set of conventions that keep downstream flakes
configuration-only.

## Documentation structure

The docs follow [Diátaxis](https://diataxis.fr/):

- **Tutorials** teach the first successful adoption.
- **How-to guides** answer a specific question, such as adding an overlay or a
  dev shell.
- **Reference** describes one public API at a time.
- **Explanation** covers the reasoning behind the design.

Start with the [first downstream flake](tutorials/first-downstream-flake.md),
use the [how-to guides](guides/adoption.md) while working, and consult the
[reference](reference/mkflake.md) when you need details.

## What lives here

- The `self.*` namespace and its `self.lib` mirror.
- Overlays that become `packages` and `apps`.
- The machine registry that becomes `nixosConfigurations`.
- Dev modules, the dev shells they generate, and their tests.
- GitHub workflows generated from dev shell declarations.
- NixOS container tests, live containers, and benchmarks.
- Package overlays for shared runtime assets.

## Conventions

- **Everything lives under `self`.** Configuration is mirrored under `self.lib`
  so a single `selfLib` handle can reach it.
- **`self` and `flake` are independent flags.** A value can feed the `self`
  mirror, the flake outputs, both, or neither.
- **`makeFlake` is the entrypoint.** A downstream flake calls
  `haraspkgs.lib.makeFlake` instead of assembling the core modules by hand.
- **Every Nix file is a flake-parts module.** The top-level flake imports `src/`
  and, when it exists, `tests/`.
- **Docs and tests roughly follow the source tree.** Each `src/dev/<module>.nix`
  gets `tests/dev/<module>.nix` and a page under each Diátaxis quadrant's `dev/`
  folder. Pure library helpers are tested in `tests/unit/`; shared mechanics
  stay in the top-level dev pages and `tests/unit/dev.nix`.
- **Repository files are generated.** Dev modules own `.gitignore`,
  `.gitattributes`, `.github/workflows/*.yaml`, `LICENSE.md`, and
  `CODE_OF_CONDUCT.md`; committed copies are mirrors. Tool configuration such as
  EditorConfig is delivered through bwrap files instead of committed files.
- **Systems come from flake-parts.** `haraspkgs` defaults the normal `systems`
  option; there is no separate `self.systems` option.
