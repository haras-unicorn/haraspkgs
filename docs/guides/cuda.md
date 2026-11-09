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

This also gives the package set the `nixos-test-driver` patch that binds the
host `/run` into GPU test containers.

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
        containers.container =
          { pkgs, ... }:
          {
            systemd.services.cuda-check = {
              wantedBy = [ "multi-user.target" ];
              path = [ pkgs.cudaPackages.saxpy ];
              script = "saxpy 2>&1";
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
            };
          };

        testScript = ''
          start_all()
          container.wait_for_unit("cuda-check.service")
        '';
      };
  };
}
```

The guest module only gives the container access to the GPU, so the test starts
its own `cuda-check`, a oneshot service that runs `pkgs.cudaPackages.saxpy`. GPU
tests must use `containers`, not QEMU nodes.

## Test the GPU outside CI

CI has no GPU, so keep the GPU tests out of `checks`. Expose them as packages
from a separate package set with CUDA turned on, and build them on a machine
that has the `cuda` and `nvidia-gpu` system features. Your main package set
stays without CUDA, so nothing else is rebuilt against it:

```nix
{ selfLib, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = selfLib.pkgs.makePkgs {
        inherit system;
        config = {
          cudaSupport = true;
          allowUnfree = true;
        };
      };
    in
    {
      packages = {
        cuda-sandbox-test =
          pkgs.runCommand "cuda-sandbox-test"
            {
              nativeBuildInputs = [ pkgs.cudaPackages.saxpy ];
              requiredSystemFeatures = [
                "cuda"
                "nvidia-gpu"
              ];
            }
            ''
              saxpy
              touch "$out"
            '';

        cuda-nixos-test = pkgs.${selfLib.overlays.namespace}.makeNixosTest {
          name = "cuda";
          value = _: {
            containers.agent =
              { pkgs, ... }:
              {
                systemd.services.cuda-check = {
                  wantedBy = [ "multi-user.target" ];
                  path = [ pkgs.cudaPackages.saxpy ];
                  script = "saxpy 2>&1";
                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                  };
                };
              };

            testScript = ''
              start_all()
              agent.wait_for_unit("cuda-check.service")
            '';
          };
        };
      };
    };
}
```

The first package runs `saxpy` in the build sandbox, the second in a NixOS test
container. The package set gets the `nixos-test-driver` patch by itself, because
the patch is part of the overlays and applies when `cudaSupport` is on. To run
GPU containers in a build, see [podman in builds](../reference/podman.md).
`nix build .#cuda-sandbox-test` builds one of them.

See the [CUDA reference](../reference/cuda.md) for the exported helpers.
