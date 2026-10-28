# Overlays

Overlays are defined under `self.overlays.overlays`. Each entry participates in
a dependency graph and can feed `self`, the flake outputs, or both.

## Shape

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

The overlay function writes un-namespaced attributes. `haraspkgs` applies the
configured namespace after composition, so the package becomes
`pkgs.harasPackages.hello` and `packages.<system>.hello`.

## Options

<!-- markdownlint-disable MD013 -->

| Option                  | Type     | Default          | Description                                    |
| ----------------------- | -------- | ---------------- | ---------------------------------------------- |
| `namespace`             | string   | `"selfPackages"` | Namespace assigned to overlay results.         |
| `overlays.<name>.name`  | string   | attribute name   | Overlay name used by dependency matching.      |
| `overlays.<name>.deps`  | strings  | `[]`             | Exact names or `/regex/` dependencies.         |
| `overlays.<name>.self`  | bool     | `true`           | Include the overlay in the `self` package set. |
| `overlays.<name>.flake` | bool     | `false`          | Export the overlay through `flake.overlays`.   |
| `overlays.<name>.value` | function | required         | Overlay function, `final: prev: attrs`.        |

<!-- markdownlint-enable MD013 -->

The default namespace is overridden to `harasPackages` by this flake.

## Dependencies

Dependencies are exact names or slash-delimited regexes matched against the
whole overlay name:

```nix
{
  deps = [
    "base"
    "/runtime-.*/"
  ];
}
```

The graph is expanded transitively, topologically sorted, and composed with
`lib.composeManyExtensions`. Cycles and undefined dependencies fail with an
assertion error.

## Outputs

- `flake.overlays.<name>` is the composed overlay for each `flake = true` entry.
- `flake.overlays.default` composes every `flake = true` entry.
- `packages.<system>.<name>` and `apps.<system>.<name>` come from the composed
  flake overlays under the namespace.
- `self.lib.<system>.overlays` contains the composed `packages` and `other`
  values.
- `self.lib.pkgs.overlays` receives the namespace overlay built from
  `self = true` entries, so the same packages are available in `perSystem` and
  dev shells.

## Shell wrapper helper

The `shell` overlay adds one function under the namespace:

```nix
pkgs.harasPackages.makeBubblewrapWrapper {
  package = pkgs.hello;
  name = "example-wrapper";
  arguments = [ "--flag" ];
  env.EXAMPLE = "1";
  stdin = null;
  files = {
    ".editorconfig" = {
      mode = "ro";
      text = "root = true\n";
    };
  };
  runtimeInputs = [ ];
  network = false;
  bwrapArgs = [ ];
}
```

<!-- markdownlint-disable MD013 -->

| Argument        | Type               | Default             | Description                                                                |
| --------------- | ------------------ | ------------------- | -------------------------------------------------------------------------- |
| `package`       | package            | required            | Tool executed by the wrapper.                                              |
| `name`          | string             | `<package>-wrapped` | Wrapper derivation name.                                                   |
| `arguments`     | list of string     | `[]`                | Fixed arguments inserted before the caller's `"$@"`.                       |
| `env`           | attrs of string    | `{}`                | Environment variables exported by the wrapper.                             |
| `stdin`         | path or null       | `null`              | File redirected to the wrapped command's standard input.                   |
| `files`         | attrs of submodule | `{}`                | Files staged in an overlay or bound, relative to the project root or `~/`. |
| `runtimeInputs` | list of package    | `[]`                | Extra commands available to the wrapper.                                   |
| `network`       | bool               | `false`             | Use the `bwrap.network` profile instead of `bwrap.local`.                  |
| `bwrapArgs`     | list of string     | `[]`                | Extra static arguments passed to `bwrap`.                                  |

<!-- markdownlint-enable MD013 -->

Each `files.<path>` value is a submodule:

- `mode` is `"ro"` (default) or `"rw"`.
- `source` is a store path or derivation.
- `text` is literal text written to the store.

Paths are relative to the project root, except paths starting with `~/`, which
are relative to `$HOME`. `source` and `text` are mutually exclusive.
`mode = "rw"` cannot use either; it only binds the target path to itself. With
neither set, the target path is bound to itself.

The wrapper uses `bubblewrap` and `writeShellApplication`. Its base arguments
are `self.lib.bwrap.local` by default, or `self.lib.bwrap.network` when
`network = true`. The local profile unshares all namespaces and binds the store
and system paths read-only, including `/etc/passwd` and `/etc/group`, without
network configuration. The network profile adds `--share-net` plus `/etc/hosts`,
`/etc/nsswitch.conf`, `/etc/resolv.conf`, and `/etc/ssl`. On top of the profile,
the wrapper binds `/nix`, the current home directory, and `/run` read-only,
binds the project root read-write, and changes to the caller's current
directory. The project root is found with `flake-root` at runtime.

Files with `source` or `text` are symlinked into a temporary staging directory
under `$XDG_CACHE_HOME/haraspkgs` (default `~/.cache/haraspkgs`) and exposed as
a read-only overlay lower layer, so `bwrap` sees them without writing into the
checkout. The project root is the overlay upper layer, so edits persist
normally. The wrapper runs the command as a child so an `EXIT` trap can remove
the staging and work directories, and it never deletes the project root or its
parent directories. In a Nix build sandbox (`NIX_BUILD_TOP` is set) and on
non-Linux systems it falls back to writing the files into the project root and
running the command directly; cleanup still happens. This is what lets dev tests
exercise wrappers in CI.

The shell overlay merges global `bwrap.files` into every wrapper; explicit
`files` entries win for the same key. `stdin`, `network`, and `bwrapArgs` are
static.

Home entries are bound separately from the repository overlay. A bound `~/` path
is created with `mkdir -p` if missing and then bound with its configured mode. A
provided `~/` path is bound read-only, with a temporary mount point created when
the destination does not exist. The Helix wrapper uses `~/.cache/helix` so `hx`
can write `helix.log` without making the rest of `$HOME` writable.

The overlay is exported through `flake.overlays.shell`; `src/overlays/dev.nix`
extends the evaluated shell `pkgs` with it, but the flake's own package set does
not include it.

## Dev shell helpers

The `dev` overlay adds `evaluateDevShellAttrs` and `makeDevTest` under the
namespace. `evaluateDevShellAttrs` turns dev shell modules into `mkShell`
derivations. `makeDevTest` wraps that evaluator into a test derivation; it is
used by the declarative [`self.devTests`](dev-tests.md) API.

## Helpers

The pure graph helpers live under `self.lib.overlays`:

- `matching`
- `directDeps`
- `transitiveDeps`
- `composeOverlay`
- `composeOverlayAttrs`
- `makeUndefinedDepsAssertion`
- `namespaceOverlay`
- `overlayAttrs`
- `overlayList`
- `makeOverlayAttrs`
- `makeOverlayResult`

## Related

- [Add an overlay](../guides/overlays.md)
- [Why overlays are a graph](../explanation/overlays.md)
