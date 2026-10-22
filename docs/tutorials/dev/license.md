# Generate a license

The `license` module reads an SPDX license text and writes it to the repository
when the shell starts.

## Enable a license

```nix
{
  self.devShells.default.value = {
    license = {
      enable = true;
      spdx = "MIT";
      attrs."<year> <copyright holders>" = "2026 Haras";
    };
  };
}
```

## Enter the shell

```console
$ nix develop
> writing
write LICENSE
$ sed -n '1,4p' LICENSE
MIT License

Copyright (c) 2026 Haras
```

The default file is `LICENSE`. Set `path` to change it, and add entries to
`attrs` for any placeholders the chosen license uses. The replacement is a plain
string substitution, so the key must match the placeholder exactly. Commit the
generated file, because GitHub reads it before the shell exists; the self shell
uses `LICENSE.md` with SPDX `MIT`.

Next, read [how to generate a license](../../guides/dev/license.md) and the
[license reference](../../reference/dev/license.md).
