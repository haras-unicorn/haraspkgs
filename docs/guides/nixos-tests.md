# Add a NixOS test

Declare a container test under `self.nixosTests`. Every test is realized as
`self.lib.nixosTests.<system>.<name>`.

## Define a test

```nix
{ ... }:
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

`name` defaults to the attribute name, so the example produces the
`nixos-test-example` check and a test named `nixos-test-example`. Set
`flake = true` to build the test as part of `nix flake check`.

## Keep a test out of checks

Omit `flake = true` (the default is `self = true`) to keep a realized test in
`self.lib.nixosTests` without building it as part of `nix flake check`.

## CUDA tests

CUDA is controlled by the package set:

```nix
{
  self.nixpkgs.config.cudaSupport = true;
}
```

When CUDA support is on, the harness applies `self.lib.cuda.testModule` to the
test and `self.lib.cuda.guestModule` to the test defaults.

## Container tests

Tests use `containers.<name>` rather than `nodes.<name>`. The harness does not
configure QEMU nodes.

## Outputs

- `self.lib.nixosTests.<system>.<name>` contains every made test.
- Tests with `flake = true` become `perSystem.checks.nixos-test-<name>`.
