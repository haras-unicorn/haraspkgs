# Describe your languages

The `languages` module records which language servers and formatters belong to
each language. It writes no files; editor modules consume the registry later.

## Configure the registry

```nix
{
  self.devShells.default.value =
    { pkgs, ... }:
    {
      languages = {
        servers.nil = {
          command = "${pkgs.nil}/bin/nil";
        };

        languages.nix = {
          servers = [ "nil" ];
          formatter = {
            command = "${pkgs.nixfmt}/bin/nixfmt";
          };
        };
      };
    };
}
```

The server name is the key under `languages.servers`; a language lists the
server names it uses. `auto-format` defaults to `true`, and the formatter is
optional.

The registry is part of the evaluated shell module. It does not add packages,
generate files, or start servers by itself. Editor and formatter modules read
the same values instead of keeping their own server lists.

Next, read [how to configure languages](../../guides/dev/languages.md) and the
[registry reference](../../reference/dev/languages.md).
