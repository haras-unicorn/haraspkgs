# Language registry module

The `languages` module is exported through `flake.devModules.languages` and
included in the default dev module group. It defines `languages.*` options and
produces no files or packages by itself.

## Options

<!-- markdownlint-disable MD013 -->

| Field                                            | Type           | Default  | Description                                             |
| ------------------------------------------------ | -------------- | -------- | ------------------------------------------------------- |
| `languages.servers.<name>.command`               | string         | required | Command used to start the server.                       |
| `languages.servers.<name>.arguments`             | list of string | `[]`     | Extra arguments passed to the server.                   |
| `languages.servers.<name>.config`                | anything       | `{}`     | Configuration passed to the server through LSP.         |
| `languages.languages.<name>.servers`             | list of string | `[]`     | Names of servers used with the language.                |
| `languages.languages.<name>.auto-format`         | bool           | `true`   | Whether to automatically format files for the language. |
| `languages.languages.<name>.formatter.command`   | string         | required | Formatter command, when a formatter is configured.      |
| `languages.languages.<name>.formatter.arguments` | list of string | `[]`     | Formatter arguments, when a formatter is configured.    |

<!-- markdownlint-enable MD013 -->

## Behavior

`languages.servers` is keyed by a stable server name. A language refers to those
names through `languages.languages.<name>.servers`; the registry does not start
any process or validate that the command exists.

`formatter` is `null` by default. Setting it to an attribute set makes the
language's `formatter.command` and `formatter.arguments` available to editor
modules. `auto-format` only records policy; the consumer decides how to apply
it.

## Outputs

`languages` contributes only module configuration. It does not add files,
`packages`, `passthru`, or CLI commands.

## Related

- [Describe your languages](../../tutorials/dev/languages.md)
- [Configure languages](../../guides/dev/languages.md)
- [The language registry](../../explanation/dev/languages.md)
- [devModule](../dev-module.md)
