{ selfLib, ... }:

# These are packages and not checks on purpose: they need a GPU and the `cuda`
# and `nvidia-gpu` build features, which CI does not have, so `nix flake check`
# must not build them. `dev test-cuda` builds them.

{
  perSystem =
    { system, ... }:
    let
      # The main package set stays without CUDA so the other packages and
      # checks do not rebuild against it.
      pkgs = selfLib.pkgs.makePkgs {
        inherit system;
        config = {
          cudaSupport = true;
          allowUnfree = true;
        };
      };

      sandboxTest =
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

      containerTest =
        let
          image = pkgs.dockerTools.buildImage {
            name = "cuda-container-test";
            tag = "latest";
            copyToRoot = [ pkgs.busybox ];
          };

          script = pkgs.${selfLib.overlays.namespace}.makePodmanScript {
            name = "cuda-container-test";
            cuda = true;
            text = ''
              podman --remote load --input ${image} > /dev/null
              podman --remote run --rm --device nvidia.com/gpu=all \
                localhost/cuda-container-test:latest \
                /bin/ls /dev/nvidia0 /dev/nvidiactl /dev/nvidia-uvm
            '';
          };
        in
        pkgs.runCommand "cuda-container-test"
          {
            requiredSystemFeatures = [
              "uid-range"
              "cuda"
              "nvidia-gpu"
            ];
          }
          ''
            ${pkgs.lib.getExe script}
            touch "$out"
          '';

      # The harness adds the cuda and nvidia-gpu features and the guest module
      # to every test when the package set has cudaSupport, so the test itself
      # only runs saxpy in the container.
      nixosTest = pkgs.${selfLib.overlays.namespace}.makeNixosTest {
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
    in
    {
      packages = {
        cuda-sandbox-test = sandboxTest;
        cuda-container-test = containerTest;
        cuda-nixos-test = nixosTest;
      };
    };
}
