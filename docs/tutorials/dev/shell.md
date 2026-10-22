# Your first dev shell module

This tutorial adds a small development shell to a downstream flake. It assumes
the flake already calls `haraspkgs.lib.makeFlake`.

## Add the module

Create a flake-parts module beside the other modules:

```nix
{
  self.devModules.hello = {
    value =
      { pkgs, ... }:
      {
        packages = [ pkgs.hello ];
        env.HELLO = "world";
        shellHook = "hello";
      };
  };
}
```

`self.devModules` entries are available to every shell. The `packages` field
adds commands to `PATH`, `env` exports variables, and `shellHook` runs in bash
when the shell starts.

## Add a shell

Select the environment for a named shell:

```nix
{
  self.devShells.default = {
    flake = true;
    value = { };
  };
}
```

## Enter it

```console
$ nix develop
> hello
Hello, world!
$ echo "$HELLO"
world
```

Next, read [how to use the shell module](../../guides/dev/shell.md) and the
[shell reference](../../reference/dev/shell.md).
