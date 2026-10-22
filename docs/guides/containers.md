# Add a live container

Declare a systemd-nspawn guest under `self.containers`.

## Define a container

```nix
{ pkgs, ... }:
{
  self.containers.agent = {
    value =
      _:
      {
        environment.systemPackages = [ pkgs.hello ];
      };
  };
}
```

`name` defaults to the attribute name. The `value` function receives the
arguments passed when the container is realized.

## Configure nspawn paths

Override the generic `virtualisation.*` options when the defaults do not fit:

```nix
{
  self.containers.agent.value =
    _:
    {
      virtualisation.rootDir = "/var/lib/agents/agent/root";
      virtualisation.stateDir = "/var/lib/agents/agent/state";
      virtualisation.environmentFile = "/run/agent.env";
    };
}
```

## Build the container

`self.lib.containers.<system>.<name>` is a function from arguments to the
realized container. The arguments are passed to the container's `value`
function, so one declaration can produce different containers. Call it and
expose the result:

```nix
{ self, ... }:
{
  flake.containers.agent = self.lib.containers.x86_64-linux.agent { };
}
```

The result is `{ container, nspawn; }`:

```console
nix build .#containers.agent.container
nix build .#containers.agent.nspawn
```

The nspawn wrapper is `run-nspawn`. It accepts `--env-file`, `--root-dir`, and
`--state-dir` before passing the remaining arguments to `systemd-nspawn`.

## Enable CUDA

CUDA is controlled by the package set:

```nix
{
  self.nixpkgs.config.cudaSupport = true;
}
```

When CUDA support is on, the container guest receives
`self.lib.cuda.guestModule` automatically.

## Related

- [Containers reference](../reference/containers.md)
- [Use CUDA](cuda.md)
