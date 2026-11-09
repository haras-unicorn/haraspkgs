# Podman in builds

The `podman` overlay adds three helpers under the namespace.

## `makePodmanImage`

```nix
pkgs.harasPackages.makePodmanImage {
  imageName = "postgres";
  imageDigest = "sha256:...";
  hash = "sha256-...";
}
```

Takes the arguments of `dockerTools.pullImage` and returns the image archive
with the setuid and setgid bits of every file cleared. The Nix build sandbox
filters `chmod` calls that set those bits, so the daemon fails to unpack layers
that have them. Layer digests and the image configuration are rewritten to
match; the image name and tags stay the same. Pass the result to `images` or
`podmanImages`.

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

| Argument        | Type            | Default                   | Description                                      |
| --------------- | --------------- | ------------------------- | ------------------------------------------------ |
| `name`          | string          | none                      | Name of the script.                              |
| `text`          | string          | none                      | Script body, run with the daemon available.      |
| `runtimeInputs` | list of package | `[]`                      | Extra commands on the script's `PATH`.           |
| `startTimeout`  | integer         | `10`                      | Seconds to wait for the daemon socket to appear. |
| `cuda`          | bool            | `pkgs.config.cudaSupport` | Generate a CDI spec for the GPU, see below.      |
| `images`        | list of package | `[]`                      | Image archives loaded when the daemon starts.    |

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
`PODMAN_SANDBOX_START_TIMEOUT` on the derivation to change the wait. Set the
list attribute `podmanImages` on the derivation, before wrapping it, to load
image archives when the daemon starts; `withPodman` turns it into the
`PODMAN_SANDBOX_IMAGES` variable.

## What the daemon is

When `CONTAINER_HOST` or `DOCKER_HOST` is already set, a daemon is running: one
the setup hook of `withPodman` started, or yours outside a build. Both helpers
then start nothing and only load the images listed in `PODMAN_SANDBOX_IMAGES`
into it.

Otherwise they start the daemon only when `NIX_BUILD_TOP` and `NIX_LOG_FD` are
set, which is the case in a Nix build and not in `nix develop`. Outside a build
they start nothing and only load the images, into the daemon the machine has.

Images are loaded with `podman --remote --url "$CONTAINER_HOST" load` when
`CONTAINER_HOST` is set. Otherwise they use `docker load` if a Docker API socket
answers (`DOCKER_HOST`, or `/var/run/docker.sock` as on NixOS with
`virtualisation.podman.dockerSocket.enable`), because podman serves that API
too. As a last resort they use `podman --remote load` with its default
connection. A machine with no daemon at all fails when images are listed.

Stopping does nothing when the daemon process is gone, so a script that started
nothing stops nothing.

In a build they require root, which a derivation gets from `uid-range`, and stop
with a message naming the feature otherwise. Then they:

1. write a storage and a containers configuration in a state directory under
   `NIX_BUILD_TOP`, with the overlay driver, the netavark bridge network and
   cgroups disabled;
2. when `cuda` is on and the build has `/dev/nvidiactl`, generate a CDI spec for
   the GPU with `nvidia-ctk` into the state directory, so containers can ask for
   `--device nvidia.com/gpu=all`. The spec of the host is not used, because its
   hooks are store paths the build does not have;
3. mount `cgroup2` on `/sys/fs/cgroup`, which is an empty directory in the
   sandbox and makes crun fail without the mount;
4. mount a `tmpfs` on `/run` when it is not writable, which happens when
   required mounts such as the GPU ones create it;
5. bring up the loopback interface and enable IPv4 forwarding;
6. start `podman system service` with its own `HOME` and configuration;
7. export the variables below;
8. load the image archives listed in `PODMAN_SANDBOX_IMAGES`, if any.

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
