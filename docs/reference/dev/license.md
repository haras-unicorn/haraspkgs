# License module

The `license` module is exported through `flake.devModules.license` and included
in the default dev module group. It renders an SPDX license text through the
`file` module.

## Options

<!-- markdownlint-disable MD013 -->

| Field             | Type                   | Default                       | Description                                        |
| ----------------- | ---------------------- | ----------------------------- | -------------------------------------------------- |
| `license.enable`  | bool                   | `false`                       | Enable the generated license file.                 |
| `license.package` | package                | `pkgs.spdx-license-list-data` | Package providing the SPDX `text` output.          |
| `license.spdx`    | string                 | required                      | SPDX identifier used as `<spdx>.txt`.              |
| `license.source`  | path, package, or null | `null`                        | License text file; overrides `package` and `spdx`. |
| `license.attrs`   | attrs of string        | `{}`                          | Exact placeholder substitutions.                   |
| `license.path`    | string                 | `"LICENSE"`                   | Path of the generated file.                        |

<!-- markdownlint-enable MD013 -->

## Behavior

When `source` is `null`, the module reads
`<license.package.text>/text/<license.spdx>.txt`. The package defaults to
`pkgs.spdx-license-list-data`, whose `text` output contains the SPDX plain-text
licenses. Updating nixpkgs updates the available license texts.

The text is passed through `lib.replaceStrings` with `license.attrs` as the
search and replacement lists. No placeholder is inserted automatically. The
result is written with the `file` module, which trims surrounding whitespace and
adds a final newline.

Set `license.source` to a path or package when the text is not in the SPDX
dataset or when the build must not read the package output.

## Outputs

- `file.<path>.text` contains the rendered license.
- The self shell enables SPDX `MIT`, writes `LICENSE.md`, and commits the
  generated file because GitHub reads it.
- The file is written when the shell starts by the `file` module.
- The module does not add packages or CLI commands.

## Related

- [Generate a license](../../tutorials/dev/license.md)
- [Configure the license](../../guides/dev/license.md)
- [Why the license module is a text generator](../../explanation/dev/license.md)
- [File module](file.md)
- [devModule](../dev-module.md)
