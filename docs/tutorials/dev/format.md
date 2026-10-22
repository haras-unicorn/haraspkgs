# Format your repository

The `format` module configures treefmt and exposes the result as the flake
formatter and as a `format` check. It is exported as `flake.devModules.format`
and included in the default dev module group.

## Add formatters

Register formatters on the default shell:

```nix
{
  self.devShells.default = {
    flake = true;
    value =
      { pkgs, ... }:
      {
        format.formatters = {
          nixfmt = {
            packages = [ pkgs.nixfmt ];
            command = "nixfmt";
            includes = [ "*.nix" ];
          };

          prettier = {
            packages = [ pkgs.prettier ];
            command = "prettier";
            options = [ "--write" ];
            includes = [ "*.json" "*.md" ];
          };
        };
      };
  };
}
```

## Format and check

```bash
nix fmt
nix flake check
```

`nix fmt` rewrites files. `nix flake check` runs the same formatters with
`--fail-on-change`, so it fails when a file is not formatted. The formatter is
taken from the `default` dev shell. `dev format` runs the same treefmt
configuration directly when you want immediate output.

Generated files are formatted when the shell starts. Set `format = false` on a
file entry to keep exact text, and pass formatter configs as store paths instead
of committing them.

Next, read [how to configure formatting](../../guides/dev/format.md) and the
[format reference](../../reference/dev/format.md).
