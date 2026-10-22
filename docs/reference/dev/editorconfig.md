# EditorConfig module

The `editorconfig` module is exported through `flake.devModules.editorconfig`
and included in the default dev module group. It contributes an EditorConfig
file to the shell's global bwrap files instead of writing a repository file.

## Options

<!-- markdownlint-disable MD013 -->

| Field                   | Type                           | Default           | Description                             |
| ----------------------- | ------------------------------ | ----------------- | --------------------------------------- |
| `editorconfig.enable`   | bool                           | `false`           | Enable the generated EditorConfig file. |
| `editorconfig.path`     | string                         | `".editorconfig"` | Path of the generated file.             |
| `editorconfig.settings` | attrs of attrs of str/int/bool | `{}`              | EditorConfig sections keyed by glob.    |

<!-- markdownlint-enable MD013 -->

## Rendering

The file begins with:

```ini
root = true
```

Each section is written as `[glob]`, followed by one `name = value` line per
entry. Sections and entries are sorted by attribute name. Boolean values are
written as lowercase `true` or `false`; integers use their decimal form.

## Outputs

- `bwrap.files.<path>.text` contains the rendered configuration.
- Wrapped commands stage the file outside the checkout and expose it through a
  read-only overlay lower layer; the repository never keeps a copy.
- The module does not add packages or CLI commands.

## Related

- [Generate EditorConfig](../../tutorials/dev/editorconfig.md)
- [Configure EditorConfig](../../guides/dev/editorconfig.md)
- [Why EditorConfig is the formatting source of truth](../../explanation/dev/editorconfig.md)
- [File module](file.md)
- [devModule](../dev-module.md)
