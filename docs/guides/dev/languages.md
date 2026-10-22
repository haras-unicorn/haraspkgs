# Configure languages

The `languages` module is editor-agnostic data. Use it to describe the language
servers a repository uses and which languages they serve.

## Define a server

```nix
{
  languages.servers.nil = {
    command = "${pkgs.nil}/bin/nil";
    arguments = [ ];
    config = { };
  };
}
```

`command` is required. `arguments` are extra server arguments, and `config` is
passed to the server through LSP by the consuming editor module.

## Map a language

```nix
{
  languages.languages.nix = {
    servers = [ "nil" ];
    auto-format = true;
    formatter = {
      command = "${pkgs.nixfmt}/bin/nixfmt";
      arguments = [ ];
    };
  };
}
```

A language may list several servers. Set `auto-format = false` when the language
should not be formatted automatically. The formatter is optional; leaving it
`null` means the editor module has no formatter to use for that language.

## Keep it data-only

The module does not add `command` packages to `packages`, does not generate
editor files, and does not depend on a particular editor. Add the packages in
the module that actually starts the server or formatter, and keep this registry
as the shared description of the mapping.

See the [language registry reference](../../reference/dev/languages.md) for the
full option shape.
