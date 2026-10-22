# Benchmarks

`self.benchmarks` declares container benchmark harnesses. Each entry names a
machine, a systemd service, and the marker that service writes to its journal.
The harness waits for the marker and records the matching journal line.

## Options

<!-- markdownlint-disable MD013 -->

| Option                      | Type     | Default        | Description                                    |
| --------------------------- | -------- | -------------- | ---------------------------------------------- |
| `benchmarks.<name>.name`    | string   | attribute name | Benchmark name used in the NixOS test name.    |
| `benchmarks.<name>.machine` | string   | required       | Machine whose service journal is inspected.    |
| `benchmarks.<name>.service` | string   | required       | systemd service whose journal is inspected.    |
| `benchmarks.<name>.marker`  | string   | required       | Literal marker to wait for in the service log. |
| `benchmarks.<name>.timeout` | int      | `3600`         | Timeout for the test and the journal wait.     |
| `benchmarks.<name>.value`   | function | required       | Arguments to a deferred NixOS test module.     |

<!-- markdownlint-enable MD013 -->

## Realized benchmarks

`self.lib.benchmarks.<system>.<name>` is a function from arguments to the made
`runNixOSTest` derivation for each configured benchmark. The arguments are
passed to `benchmarks.<name>.value`, so the same benchmark can run with
different parameters.

The generated test script:

- waits for `service` journal output containing `marker`;
- writes the matching line to `driver.out_dir/benchmark.txt`;
- prints the line.

## Related

- [Run a benchmark](../guides/benchmarks.md)
- [CUDA helpers](cuda.md)
- [NixOS tests](nixos-tests.md)
- [nixpkgs](nixpkgs.md)
