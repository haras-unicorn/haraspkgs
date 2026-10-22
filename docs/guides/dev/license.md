# Generate a license

The `license` module fetches plain text from `spdx-license-list-data` and
renders it through the `file` module. Use it when the repository should not
maintain a license file by hand.

## Choose an SPDX license

```nix
{
  license = {
    enable = true;
    spdx = "Apache-2.0";
    path = "LICENSE";
  };
}
```

`spdx` must be a file name in the `text` output of `spdx-license-list-data`, for
example `MIT`, `Apache-2.0`, or `GPL-3.0-only`. The package version follows the
nixpkgs input.

## Replace placeholders

License texts contain placeholders such as `<year> <copyright holders>`:

```nix
{
  license.attrs = {
    "<year> <copyright holders>" = "2026 Haras";
  };
}
```

Every key is replaced with its value using `lib.replaceStrings`. The module does
not guess placeholders, so inspect the selected text and add the exact keys the
file contains.

## Override the source

`license.source` accepts a local file when a project needs a modified text that
is not in the SPDX dataset:

```nix
{
  license = {
    enable = true;
    spdx = "MIT";
    source = ./LICENSE.txt;
    path = "LICENSE";
  };
}
```

When `source` is set, `package` and `spdx` are not read. This is also useful in
tests and in offline builds.

## Commit the output

GitHub reads the license file without entering the shell. Commit the generated
`LICENSE.md` as a mirror. The self shell enables SPDX `MIT`, writes
`LICENSE.md`, and accepts the SPDX wording.

See the [license reference](../../reference/dev/license.md) for the full option
shape.
