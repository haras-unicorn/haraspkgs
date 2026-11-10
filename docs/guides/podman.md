# Run containers in checks

`harasPackages.makePodmanScript` and `harasPackages.withPodman` start a podman
daemon inside the Nix build sandbox, so a check can run containers. Outside the
sandbox they start nothing: they load the images you list into the Docker or
podman daemon of whoever runs them, and the wrapped command fails by itself if
there is none.

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

The sandbox has no network, so nothing can be pulled. Fetch or build images
outside the sandbox and list them, and the daemon loads them when it starts.
Images built with `dockerTools.buildImage` are tagged `localhost/<name>:<tag>`.

To use an image from a registry, fetch it with `makePodmanImage`. It takes the
arguments of `dockerTools.pullImage` and clears the setuid and setgid bits,
which the Nix build sandbox does not let the daemon create. Most images built on
a distribution have such files, and without this they fail to load.

```nix
pkgs.harasPackages.makePodmanImage {
  imageName = "postgres";
  imageDigest = "sha256:...";
  hash = "sha256-...";
  finalImageName = "docker.io/library/postgres";
  finalImageTag = "18";
}
```

The haraspkgs flake exports a few of these as `image-*` packages, for example
`pkgs.harasPackages.image-postgresql-18`, which testcontainers modules find as
`postgres:18`.

For a script, pass `images`:

```nix
pkgs.harasPackages.makePodmanScript {
  name = "probe";
  images = [ pkgs.harasPackages.image-postgresql-18 ];
  text = "podman --remote run --rm postgres:18 postgres --version";
}
```

For a derivation, set `podmanImages` on it before wrapping it with `withPodman`:

```nix
pkgs.harasPackages.withPodman (
  pkgs.runCommand "containers-check"
    {
      nativeBuildInputs = [ pkgs.python3 ];
      podmanImages = [ pkgs.harasPackages.image-postgresql-18 ];
    }
    ''
      python ${client}
      touch "$out"
    ''
)
```

The images are ordinary build inputs, so they are built first and cached like
any other derivation.

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
