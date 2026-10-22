# Use the dev CLI

The `cli` module adds a `dev` command with subcommands to the shell. It is
exported as `flake.devModules.cli` and included in the default dev module group.

## Add a command

Start with a shell command that has its own packages:

```nix
{
  self.devShells.default = {
    flake = true;
    value =
      { pkgs, ... }:
      {
        cli.commands.hello = {
          description = "Say hello.";
          packages = [ pkgs.hello ];
          commands = "hello";
        };
      };
  };
}
```

## Run it

```console
dev hello
```

`dev --help` lists every enabled subcommand. The `check` and `format` modules
also register `dev check` and `dev format`, which run the configured checks and
treefmt directly in the checkout.

Next, read [how to add a dev command](../../guides/dev/cli.md) and the
[CLI reference](../../reference/dev/cli.md).
