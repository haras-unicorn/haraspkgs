# Generate a GitHub workflow

The `workflows` module writes GitHub Actions files when the shell starts. This
tutorial adds a manual workflow that runs `nix flake check`.

## Declare the workflow

Put the declaration in the shell or a dev module:

```nix
{
  self.devShells.default.value = {
    workflows.check = {
      on = {
        pull_request = { };
        push.branches = [ "main" ];
      };
      matrix.os = [
        "ubuntu-latest"
        "macos-latest"
      ];
      installable = null;
      steps = [ { run = "nix flake check --show-trace"; } ];
    };
  };
}
```

## Enter the shell

```console
$ nix develop
> writing
write .github/workflows/check.yaml
```

The generated file contains the checkout, Nix, and Cachix steps plus the
declared `nix flake check` command. It is rendered with `lib.generators.toYAML`
and formatted with Prettier. Commit it and let the `workflows` check keep it in
sync.

Next, read [the workflows guide](../../guides/dev/workflows.md) and the
[workflows reference](../../reference/dev/workflows.md).
