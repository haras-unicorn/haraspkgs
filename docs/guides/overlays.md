# Add an overlay

Overlays are registered under `self.overlays.overlays` and exposed through the
configured namespace.

## Define an overlay

```nix
{
  self.overlays.overlays.my-tool = {
    flake = true;
    value = final: _prev: {
      my-tool = final.writeShellApplication {
        name = "my-tool";
        text = "echo my-tool";
      };
    };
  };
}
```

Write un-namespaced attributes inside the overlay; `haraspkgs` applies the
namespace after composition. The default namespace is `harasPackages`, so the
package is `pkgs.harasPackages.my-tool`. The overlay name defaults to the
attribute name and `deps` defaults to `[]`.

Set `flake = true` to export the overlay through `flake.overlays` and derive
`packages` and `apps`. Set `self = false` to keep the overlay out of the
`self.lib.<system>.overlays` package set.

## Dependencies

Overlays can depend on other overlays by name. Dependencies are composed before
the overlay that needs them.

```nix
{
  self.overlays.overlays.tools = {
    flake = true;
    deps = [ "runtime" ];
    value = final: prev: {
      my-tool = final.runCommand "my-tool" { } "${prev.runtime}/bin/runtime";
    };
  };
}
```

A dependency may also be a slash-delimited regular expression:

```nix
{
  deps = [ "/runtime-.*/" ];
}
```

Cycles and dependencies that match no overlay fail evaluation with an assertion
error.

## Wrap a tool with bwrap

Every evaluated dev shell receives the `shell` overlay. It adds
`harasPackages.makeBubblewrapWrapper`, which runs a command through `bwrap` with
a Nix-friendly default sandbox:

```nix
{ pkgs, ... }:
{
  packages = [
    (pkgs.harasPackages.makeBubblewrapWrapper {
      name = "example-wrapper";
      package = pkgs.hello;
      arguments = [ "--flag" ];
      env.EXAMPLE = "1";
    })
  ];
}
```

`files` values are attrsets with `mode` (`"ro"` or `"rw"`) and an optional
`source` or `text`. Keys are relative to the project root, or to `$HOME` when
they start with `~/`. Files with `source` or `text` are staged outside the
checkout and exposed through a read-only overlay lower layer, so they do not
appear as untracked files while the command runs. The project root is the
writable overlay upper layer, so normal edits persist. Use `files` to provide
files, to make a subpath read-only, or to make a `~/` path writable. Use
`network = true` when the wrapped command needs the host network; otherwise the
wrapper uses the local profile, which unshares all namespaces and omits network
configuration. Use `runtimeInputs` for extra tools, `stdin` for a file used as
standard input, and `bwrapArgs` for extra static `bwrap` arguments.

```nix
{
  files = {
    ".editorconfig".text = "root = true\n";
    "~/.cache/example".mode = "rw";
  };
}
```

The base arguments come from `self.lib.bwrap.local` or `self.lib.bwrap.network`.
The local profile unshares all namespaces, binds the store and system paths
read-only (including `/etc/passwd` and `/etc/group`), and provides `/proc`,
`/dev`, and a temporary `/tmp`. The network profile adds `--share-net`, the
network configuration files, and `/etc/ssl`. On top of either profile, the
wrapper binds `/nix`, the current home directory, and `/run` read-only, mounts
the project root read-write (directly or as an overlay upper layer), and changes
to the caller's current directory. The wrapper appends `"$@"` after its fixed
`arguments`.

The overlay is exported as `flake.overlays.shell` and, because it is
`self = true`, it is also part of the flake's self package overlays. The helper
is additionally injected into the `pkgs` used to evaluate and construct dev
shells. In a Nix build sandbox, on non-Linux systems, or whenever
`HARASPKGS_MATERIALIZE` is set to a non-empty value, the wrapper writes `files`
into the checkout, runs the command directly, and still performs cleanup. Set
the variable when `bwrap` cannot run, for example inside another sandbox:

```sh
HARASPKGS_MATERIALIZE=1 example-wrapper --flag
```

See the [overlay reference](../reference/overlays.md) for the option shape.
