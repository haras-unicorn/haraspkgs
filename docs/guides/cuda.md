# Use CUDA

`haraspkgs` provides CUDA helpers for container tests and live containers. It
does not import CUDA-specific flake inputs.

## Enable CUDA in nixpkgs

```nix
{
  self.nixpkgs.config = {
    cudaSupport = true;
    allowUnfree = true;
  };
}
```

This also applies the `nixos-test-driver` patch that binds the host `/run` into
GPU test containers.

## Run a CUDA test

Enable CUDA in the package set and declare a container test. The harness applies
`self.lib.cuda.testModule` and `self.lib.cuda.guestModule` automatically:

```nix
{
  self.nixpkgs.config.cudaSupport = true;

  self.nixosTests.cuda-example = {
    flake = true;

    value =
      _:
      {
        containers.container = { };

        testScript = ''
          start_all()
          container.wait_for_unit("cuda-check.service")
        '';
      };
  };
}
```

The guest starts `cuda-check`, a oneshot service that runs
`pkgs.cudaPackages.saxpy`. GPU tests must use `containers`, not QEMU nodes.

See the [CUDA reference](../reference/cuda.md) for the exported helpers.
