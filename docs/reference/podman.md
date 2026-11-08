# Podman in builds

The `podman` overlay adds two helpers under the namespace.

## `makePodmanScript`

```nix
pkgs.harasPackages.makePodmanScript {
  name = "probe";
  text = "podman --remote run --rm localhost/probe:latest";
  runtimeInputs = [ ];
  startTimeout = 10;
}
```

<!-- markdownlint-disable MD013 -->

| Argument        | Type            | Default | Description                                      |
| --------------- | --------------- | ------- | ------------------------------------------------ |
| `name`          | string          | none    | Name of the script.                              |
| `text`          | string          | none    | Script body, run with the daemon available.      |
| `runtimeInputs` | list of package | `[]`    | Extra commands on the script's `PATH`.           |
| `startTimeout`  | integer         | `10`    | Seconds to wait for the daemon socket to appear. |

<!-- markdownlint-enable MD013 -->

The result is a `writeShellApplication`. It starts the daemon, runs `text`, and
stops the daemon on exit.

## `withPodman`

```nix
pkgs.harasPackages.withPodman derivation
```

Returns the derivation with a setup hook in `nativeBuildInputs` and `uid-range`
merged into `requiredSystemFeatures`. The hook starts the daemon after the setup
of the build and the daemon ends with the build. Set the environment variable
`PODMAN_SANDBOX_START_TIMEOUT` on the derivation to change the wait.

## What the daemon is

Both helpers start the daemon only when `NIX_BUILD_TOP` and `NIX_LOG_FD` are
set, which is the case in a Nix build and not in `nix develop`. Outside a build
they do nothing.

In a build they require root, which a derivation gets from `uid-range`, and stop
with a message naming the feature otherwise. Then they:

1. write a storage and a containers configuration in a state directory under
   `NIX_BUILD_TOP`, with the overlay driver, the netavark bridge network and
   cgroups disabled;
2. mount `cgroup2` on `/sys/fs/cgroup`, which is an empty directory in the
   sandbox and makes crun fail without the mount;
3. mount a `tmpfs` on `/run` when it is not writable, which happens when
   required mounts such as the GPU ones create it;
4. bring up the loopback interface and enable IPv4 forwarding;
5. start `podman system service` with its own `HOME` and configuration;
6. export the variables below.

<!-- markdownlint-disable MD013 -->

| Variable                        | Value                                |
| ------------------------------- | ------------------------------------ |
| `CONTAINER_HOST`, `DOCKER_HOST` | `unix://` path of the daemon socket. |
| `TESTCONTAINERS_RYUK_DISABLED`  | `true`                               |
| `TESTCONTAINERS_HOST_OVERRIDE`  | `127.0.0.1`                          |
| `PODMAN_SANDBOX_START_TIMEOUT`  | Seconds to wait for the socket.      |

<!-- markdownlint-enable MD013 -->

The user's environment is not changed otherwise, so use `podman --remote`.
Containers cannot be limited in memory, processes or disk, because the sandbox
has no cgroup controllers.

## Related

- [Run containers in checks](../guides/podman.md)
- [Overlays](overlays.md)
