# The shell module

The base shell module is the source of the stable shell API. It declares `name`,
`packages`, `buildInputs`, `nativeBuildInputs`, `inputsFrom`, `shellHook`,
`env`, and `passthru`.

The evaluator reads only those fields from the merged dev-module config and
passes them to `pkgs.mkShell`. Options owned by other modules, such as `file`,
are configuration for those modules and never become derivation attributes.

## Package set and global files

The shell module does not take `pkgs` directly. It recreates `_module.args.pkgs`
from `config.nixpkgs`, so shell modules can add overlays without evaluating a
second flake layer. The base overlays come first, user overlays are merged in
the middle, and the global-bwrap overlay is appended last.

That final overlay wraps `makeBubblewrapWrapper` and merges `bwrap.files` into
each call. It is lazy: the files are read only when a wrapper is built. This is
how EditorConfig, CSpell, and other configuration reach every wrapped tool
without a committed file.

## Shell hook language

`shellHook` is a bash snippet. `nix develop` and `nix-shell` evaluate it in
bash, and a child Nushell process cannot export environment variables back into
the parent shell. Do not run hooks through Nushell; use `env` for environment
variables and call Nushell applications from bash hooks for commands. Replacing
the shell with `exec nu` would break `nix develop -c`, direnv, and
`nix print-dev-env`.

## Related

- [Use the shell module](../../guides/dev/shell.md)
- [Shell module reference](../../reference/dev/shell.md)
