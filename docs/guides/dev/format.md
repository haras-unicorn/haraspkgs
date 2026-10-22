# Configure formatting

The `format` module is exported as `flake.devModules.format` and included in the
default group. It owns one treefmt configuration and turns it into two actions:

- a mutating formatter, exposed through `perSystem.formatter`,
- a read-only format check, exposed through `perSystem.checks`.

## Add formatters

```nix
{
  self.devShells.default = {
    flake = true;
    value =
      { pkgs, ... }:
      {
        format.formatters.nixfmt = {
          packages = [ pkgs.nixfmt ];
          command = "nixfmt";
          includes = [ "*.nix" ];
        };
      };
  };
}
```

Each formatter has:

- `command`: the executable to run,
- `options`: arguments passed before the files,
- `includes` and `excludes`: treefmt globs,
- `packages`: runtime dependencies for the command,
- `enable`: whether treefmt should run it.

Set `format.packages` for packages shared by every formatter. Set
`format.treefmtPackage` to use a different treefmt.

## Format generated files

The `file` module writes generated text first and then runs the same treefmt
configuration on those paths from its shell hook. Formatting is a runtime step,
so `nix flake check --all-systems` does not build formatters for foreign
systems. Set `format = false` on a file entry when the exact text matters.

Formatter configuration should be passed as store paths. For example, the self
shell writes the Prettier, Markdownlint, and markdown-link-check configs to the
store and passes the paths on the command line. No config files are committed.

## Format

```bash
nix fmt
```

`nix fmt` calls the `formatter` output. The formatter is taken from the
`default` dev shell, so keep the shell that owns the formatters named `default`
or add the same formatters there.

`nix fmt` forwards its file arguments to treefmt. With no arguments, treefmt
walks the repository using its tree root. The `cli` module also exposes
`dev format`, which runs the same treefmt configuration directly in the
checkout.

## Check

```bash
nix flake check
```

The module adds `checks.<system>.default-format`, which runs treefmt with
`--fail-on-change`. It copies `self.outPath`, so the check runs without touching
the checkout.
