# Containers

`self.containers` declares live NixOS guests that run on the host with
`systemd-nspawn`.

## Shape

```nix
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

Each entry is a submodule with `self`, `flake`, and `value`. The `value` is a
function that receives the arguments passed when the container is realized.

## Options

<!-- markdownlint-disable MD013 -->

| Option                    | Type     | Default        | Description                                        |
| ------------------------- | -------- | -------------- | -------------------------------------------------- |
| `containers.<name>.name`  | string   | attribute name | Container name used for the guest and state paths. |
| `containers.<name>.value` | function | required       | Arguments to a deferred NixOS module.              |

<!-- markdownlint-enable MD013 -->

## Realized containers

`self.lib.containers.<system>.<name>` is a function from arguments to the made
container for each configured entry:

```nix
args: {
  container = <system.build.toplevel derivation>;
  nspawn = <system.build.nspawn derivation>;
}
```

The arguments are passed to `containers.<name>.value`, so a single declaration
can be realized with different parameters. Call the function with the arguments
you want, use the result with `nix build`, or expose it as a flake output.

## Guest system

The guest is built with `inputs.nixpkgs.lib.nixosSystem` from:

- the generic nspawn module;
- the container `value`;
- a guest module that sets `system.name` and `networking.hostName`, disables the
  firewall, and defaults `system.stateVersion` to `"26.05"`;
- `self.lib.cuda.guestModule` when the configured package set has
  `cudaSupport = true`.

The nspawn module sets `boot.isNspawnContainer`, enables a read-only console,
forwards journald to `/dev/console`, and runs sshd over the nspawn unix-export
socket.

## Nspawn options

The nspawn module adds these options to the guest:

<!-- markdownlint-disable MD013 -->

| Option                                  | Type           | Default                                      | Description                                   |
| --------------------------------------- | -------------- | -------------------------------------------- | --------------------------------------------- |
| `virtualisation.cmdline`                | list of string | `[]`                                         | Arguments passed to the container init.       |
| `virtualisation.rootDir`                | string         | `/var/lib/haraspkgs-containers/<name>/root`  | Writable root directory.                      |
| `virtualisation.stateDir`               | string         | `/var/lib/haraspkgs-containers/<name>/state` | Host directory bound to `/var/lib/haraspkgs`. |
| `virtualisation.environmentFile`        | path or null   | `null`                                       | Host env file bound to `/run/haraspkgs.env`.  |
| `virtualisation.systemd-nspawn.options` | list of string | nspawn console and store bind options        | Extra `systemd-nspawn` arguments.             |

<!-- markdownlint-enable MD013 -->

## Related

- [Add a live container](../guides/containers.md)
- [CUDA helpers](cuda.md)
- [NixOS tests](nixos-tests.md)
