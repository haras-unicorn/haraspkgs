# Add a dev command

The `cli` module installs one `dev` command with subcommands. It is exported as
`flake.devModules.cli` and included in the default group.

## Add a command

Register a subcommand on a shell:

```nix
{
  self.devShells.default = {
    flake = true;
    value =
      { pkgs, ... }:
      {
        cli.commands.hello = {
          description = "Print a greeting.";
          packages = [ pkgs.hello ];
          commands = "hello";
        };
      };
  };
}
```

`commands` accepts the same value as `shellHook`: a string, a list, or
structured commands with `text`, `header`, and `depth`. Use `header` when a
subcommand runs several steps.

## Run it

```console
dev --help
dev hello
```

The CLI changes to the flake root before running a subcommand, so repository
paths are relative to the checkout.

## Built-in subcommands

The `check` and `format` modules add the standard subcommands automatically:

```console
dev check
dev format
```

`dev check` runs every enabled `check.checks` command directly in the checkout.
`dev format` runs the registered treefmt configuration directly. Neither command
calls `nix flake check` or `nix fmt`; use those for CI or when you prefer the
flake actions. The `git` module adds `dev hook-<name>` subcommands and points
the generated git hooks at them, so hooks do not need separate packages.

## Related

- [CLI reference](../../reference/dev/cli.md)
- [Configure checks](check.md)
- [Configure formatting](format.md)
