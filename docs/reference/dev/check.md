# Check module

The `check` module is exported through `flake.devModules.check` and included in
the default group. It turns named command lists into check derivations.

## Options

<!-- markdownlint-disable MD013 -->

| Field                               | Type            | Default | Description                                   |
| ----------------------------------- | --------------- | ------- | --------------------------------------------- |
| `check.packages`                    | list of package | `[]`    | Packages available to every check.            |
| `check.checks.<name>.enable`        | bool            | `true`  | Whether to expose the check.                  |
| `check.checks.<name>.packages`      | list of package | `[]`    | Packages available to this check.             |
| `check.checks.<name>.commands`      | commands        | `[]`    | Commands run by this check.                   |
| `check.checks.<name>.podman.enable` | bool            | `false` | Whether the check can run containers.         |
| `check.checks.<name>.podman.images` | list of package | `[]`    | Image archives loaded when the daemon starts. |

<!-- markdownlint-enable MD013 -->

## Behavior

For each enabled entry in `check.checks`, the module:

1. copies `self.outPath` to a writable directory,
2. runs the check's commands from that directory,
3. creates the derivation output.

The commands use the same type as `shellHook`. `check.packages` and the check's
own `packages` become `nativeBuildInputs`.

## Containers

With `podman.enable = true` the check derivation is wrapped with
[`withPodman`](../podman.md): it requires the `uid-range` system feature, gets
`pkgs.podman` on its `PATH`, and a daemon is started before the commands run.
`podman.images` become its `podmanImages`, so the daemon loads them first.

`dev check` has no build to start a daemon in. If any check enables `podman`,
the commands of every check run through [`makePodmanScript`](../podman.md) with
the images of all the checks. Outside a Nix build that script starts no daemon.
It loads the images into the daemon the machine has, as described in
[Podman in builds](../podman.md), and the commands then use that daemon.

## Outputs

- `passthru.checks.<name>` on each evaluated shell.
- `perSystem.checks.<shell>-<name>` in the flake.
- `self.lib.<system>.devShells.<shell>.passthru.checks.<name>` in the self
  mirror.

## Related

- [Configure checks](../../guides/dev/check.md)
- [The check module](../../explanation/dev/check.md)
- [devModule](../dev-module.md)
