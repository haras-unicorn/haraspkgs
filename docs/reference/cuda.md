# CUDA helpers

`self.lib.cuda` contains reusable pieces for CUDA-enabled containers and tests.
The values are exported through `flake.lib.cuda`.

CUDA support comes from nixpkgs and the downstream package policy:

```nix
{
  self.nixpkgs.config.cudaSupport = true;
}
```

## `hostModule`

Applies `programs.nix-required-mounts` when the package set has
`cudaSupport = true`. Use it on the host that runs GPU containers.

## `testModule`

Adds the `cuda` and `nvidia-gpu` required features to a NixOS test.

## `guestModule`

The guest module for containers and tests. It:

- enables `cudaSupport` and `allowUnfree` in the guest;
- starts the `cuda-check` oneshot service running `pkgs.cudaPackages.saxpy`;
- adds the NVIDIA device bind mounts and `/run/opengl-driver`.

The guest uses `/host/run/opengl-driver` inside the test driver and
`/run/opengl-driver` on a live host.

## Gating

The nixpkgs module applies the `nixos-test-driver` GPU patch when
`self.nixpkgs.config.cudaSupport = true`.

## Related

- [Configure CUDA](../guides/cuda.md)
- [NixOS tests](nixos-tests.md)
- [nixpkgs](nixpkgs.md)
