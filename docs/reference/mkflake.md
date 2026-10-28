# makeFlake

`haraspkgs.lib.makeFlake` is the flake entrypoint. Call it from a downstream
`outputs` function:

```nix
haraspkgs.lib.makeFlake {
  inherit inputs;
  modules = [ ./src ];
}
```

## Arguments

<!-- markdownlint-disable MD013 -->

| Argument      | Type            | Description                                                      |
| ------------- | --------------- | ---------------------------------------------------------------- |
| `inputs`      | attrs           | Downstream flake inputs, forwarded to `flake-parts.lib.mkFlake`. |
| `modules`     | list of modules | Modules; directory entries are imported with `import-tree`.      |
| `specialArgs` | attrs           | Extra module arguments, forwarded to every module evaluation.    |
| `...`         | attrs           | Any other argument is forwarded to `flake-parts.lib.mkFlake`.    |

<!-- markdownlint-enable MD013 -->

## Behavior

- Bootstraps a freeform `self` evaluation to collect `self.flakeModules`.
- Expands directory entries in `modules` with `import-tree`.
- Passes file paths, functions, and attribute sets through as modules.
- Imports every haraspkgs module exported through `flake.flakeModules`,
  including `base`.
- Defines `self.overlays` in the base module, so overlay submodule defaults are
  available during bootstrap and exported modules can read provider overlays
  from `selfLib.overlays`.
- Keeps the bootstrap independent from final flake outputs: exported module
  values use the provider `selfLib` captured at haraspkgs evaluation time, not
  the downstream `self` outputs. See
  [the self namespace](../explanation/self-namespace.md#provider-and-downstream-scopes).
- Calls `flake-parts.lib.mkFlake` with the collected modules.
- Uses `flake-parts` and `import-tree` from the `haraspkgs` closure unless the
  downstream provides them.

`modules` defaults to `[ ]`. The top-level `haraspkgs` flake passes
`[ ./src ./tests ]`.

## Downstream requirements

- A `nixpkgs` input, followed into `haraspkgs`:

  ```nix
  inputs.haraspkgs.inputs.nixpkgs.follows = "nixpkgs";
  ```

- A module list. Directory entries are imported with `import-tree`; other
  entries are normal flake-parts modules.
- `home-manager` when using [machines](machines.md).

## Exported modules

`haraspkgs` exports all of its flake modules, including `base`, through
`flake.flakeModules`. `flake.flakeModules.default.imports` is the grouped form.
The same policy applies to dev modules: every haraspkgs-provided dev module is
available through `flake.devModules`, and `flake.devModules.default.imports`
groups them for shells.

`makeFlake` consumes those exported modules. You can also inspect or import an
individual module from `flake.flakeModules` or `flake.devModules` when a flake
needs to assemble a narrower configuration.

## Values

Values under `self.*` use `self` and `flake` flags. `self = true` includes the
value in the `self` mirror; `flake = true` exports it to the flake outputs.

Haraspkgs-provided modules use `self = false; flake = true;`: they belong to the
provider's exported module set, not to downstream `self` configuration. Modules
defined by a downstream flake default to `self = true; flake = false;`. If a
downstream module is intentionally exported, set `self = false; flake = true;`
so it is not imported twice.

## Conventions

- Depend on consumer inputs when they are present and fall back to the
  provider's input otherwise:

  ```nix
  nixpkgs = if inputs ? nixpkgs then inputs.nixpkgs else selfLib.lib.inputs.nixpkgs;
  ```

  Shared modules read those inputs lazily, so a downstream flake can override
  them without hardcoding a source. The recursive self filters stop at flake
  inputs, so `selfLib.lib.inputs` does not force unrelated flake outputs.

- Never hardcode system triplets. Generate system-specific outputs with
  `lib.genAttrs config.systems`, and use the `system` and `pkgs` arguments from
  `perSystem` otherwise. `config.systems` remains the single source of truth.

## Related

- [The self namespace](../explanation/self-namespace.md)
- [Adopt haraspkgs](../guides/adoption.md)
