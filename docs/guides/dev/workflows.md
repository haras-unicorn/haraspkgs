# Add a GitHub workflow

The `workflows` module writes GitHub Actions YAML from the shell hook. Declare a
workflow in a shell, enter the shell once to generate the file, and commit the
generated copy.

## Declare a workflow

```nix
{
  self.devShells.default.value = {
    workflows.docs = {
      on.push.branches = [ "main" ];
      permissions = {
        contents = "read";
        "id-token" = "write";
        pages = "write";
      };
      installable = ".#docs";
      steps = [
        {
          uses = "actions/upload-pages-artifact@v3";
          "with".path = "./result";
        }
        { uses = "actions/deploy-pages@v4"; }
      ];
    };
  };
}
```

The base steps install Nix, configure Cachix, and run
`nix build --show-trace .#docs`. `steps` are appended after them.

## Use a matrix

Set `matrix` and the job runs on `${{ matrix.os }}`:

```nix
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
  steps = [ { run = "nix flake check --all-systems --show-trace"; } ];
};
```

`installable = null` removes the default build step; use `steps` for commands
that are not `nix build`.

## Generate and verify

```console
$ nix develop
> writing
write .github/workflows/check.yaml
> formatting generated files
```

The `workflows` passthru check is part of `nix flake check`, so a stale
committed workflow fails CI. The renderer uses `lib.generators.toYAML`; the
`file` module formats the generated YAML at shell entry, and the drift check
runs Prettier on a temporary copy in its build.
