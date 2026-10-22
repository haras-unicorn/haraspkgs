# Run a benchmark

Declare a benchmark under `self.benchmarks`. The harness runs a container NixOS
test, waits for a marker in a service journal, and records the matching line.

## Define a benchmark

```nix
{ ... }:
{
  self.benchmarks.example = {
    machine = "agent";
    service = "example.service";
    marker = "BENCHMARK RESULT:";

    value =
      _:
      {
        containers.agent = { };
      };
  };
}
```

`machine` names the container whose journal is inspected. `service` and `marker`
select the line to keep.

## Realize it

`self.lib.benchmarks.<system>.<name>` is a function from arguments to the made
`runNixOSTest` derivation. The arguments are passed to the benchmark's `value`
function, so one declaration can run with different parameters. Call it and
expose the result:

```nix
{ self, ... }:
{
  flake.benchmarks.example = self.lib.benchmarks.x86_64-linux.example { };
}
```

```console
nix build .#benchmarks.example
```

## Related

- [Benchmark reference](../reference/benchmarks.md)
- [NixOS tests](nixos-tests.md)
