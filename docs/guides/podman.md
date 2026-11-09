# Run containers in checks

`harasPackages.makePodmanScript` and `harasPackages.withPodman` start a podman
daemon inside the Nix build sandbox, so a check can run containers. Outside the
sandbox they do nothing: the wrapped command uses the Docker or podman daemon of
whoever runs it, and fails by itself if there is none.

## Wrap a script

`makePodmanScript` works like `writeShellApplication`. The daemon runs for the
length of the script, and `CONTAINER_HOST` and `DOCKER_HOST` point at it.

```nix
{
  perSystem =
    { lib, pkgs, ... }:
    let
      probe = pkgs.harasPackages.makePodmanScript {
        name = "probe";
        text = ''
          podman --remote load --input ${image}
          podman --remote run --rm localhost/probe:latest
        '';
      };
    in
    {
      checks.containers =
        pkgs.runCommand "containers-check"
          { requiredSystemFeatures = [ "uid-range" ]; }
          ''
            ${lib.getExe probe}
            touch "$out"
          '';
    };
}
```

The script cannot ask for `uid-range` itself, because the feature belongs to the
derivation that runs it. Without the feature the script stops with a message
that names it.

## Wrap a derivation

`withPodman` adds a setup hook to the derivation and merges `uid-range` into its
`requiredSystemFeatures`. The daemon starts before the first phase and lives
until the build ends. This also works for `runCommand` checks, which have no
phases.

```nix
pkgs.harasPackages.withPodman (
  pkgs.runCommand "containers-check" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python ${client} ${image}
    touch "$out"
  ''
)
```

## Provide images

The sandbox has no network, so nothing can be pulled. Build images with
`dockerTools` and load them with `podman --remote load --input <image>`. Tags of
images built that way are `localhost/<name>:<tag>`.

## Use a Docker client library

Clients such as testcontainers talk to the podman socket through `DOCKER_HOST`.
The helpers also set `TESTCONTAINERS_RYUK_DISABLED` and
`TESTCONTAINERS_HOST_OVERRIDE`, because the Ryuk image cannot be pulled and the
sandbox has no `/etc/hosts` to resolve `localhost`. Connect to published ports
on `127.0.0.1`.

## Prepare the machine

Builds that ask for `uid-range` only run where the Nix daemon allows them. Set
`experimental-features = auto-allocate-uids cgroups`,
`auto-allocate-uids = true` and `extra-system-features = uid-range` in
`nix.conf`. Workflows rendered by the `workflows` module do this on the runner
for you, and they also enable KVM and unprivileged user namespaces.

## Related

- [Podman reference](../reference/podman.md)
- [Add a GitHub workflow](dev/workflows.md)
