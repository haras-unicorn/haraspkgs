# NixOS tests

`self.nixosTests` is an attribute set of declarative container tests. Every
entry is realized under `self.lib.nixosTests.<system>.<name>` as a
`runNixOSTest` derivation.

## Shape

```nix
{
  self.nixosTests.example = {
    flake = true;

    value =
      _:
      {
        containers.agent = { };

        testScript = ''
          start_all()
          agent.succeed("true")
        '';
      };
  };
}
```

Each entry is a submodule with `self`, `flake`, and `value`. `value` is a
function that returns a deferred NixOS test module.

## Options

<!-- markdownlint-disable MD013 -->

| Option                    | Type     | Default        | Description                                |
| ------------------------- | -------- | -------------- | ------------------------------------------ |
| `nixosTests.<name>.name`  | string   | attribute name | Base name for the NixOS test.              |
| `nixosTests.<name>.value` | function | required       | Arguments to a deferred NixOS test module. |
| `nixosTests.<name>.self`  | bool     | `true`         | Include the test in `self.lib.nixosTests`. |
| `nixosTests.<name>.flake` | bool     | `false`        | Emit the test as a per-system check.       |

<!-- markdownlint-enable MD013 -->

## Outputs

- `self.lib.nixosTests.<system>.<name>` is the made test derivation.
- Each test with `flake = true` becomes `perSystem.checks.nixos-test-<name>`.
- The `runNixOSTest` name is `nixos-test-<name>`.

## Related

- [Add a NixOS test](../guides/nixos-tests.md)
- [CUDA helpers](cuda.md)
- [The self namespace](../explanation/self-namespace.md)
