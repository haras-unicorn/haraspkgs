# NOTE: https://applicative.systems/nixos-test-driver-manual/tutorials/cuda-tests

{
  self.lib.cuda = {
    flake = true;

    hostModule = { lib, pkgs, ... }: {
      programs.nix-required-mounts = lib.mkIf pkgs.config.cudaSupport {
        enable = true;
        presets.nvidia-gpu.enable = true;
      };
    };

    testModule = {
      requiredFeatures = {
        cuda = true;
        nvidia-gpu = true;
      };
    };

    guestModule =
      { pkgs, options, ... }:
      {
        nixpkgs.config = {
          cudaSupport = true;
          allowUnfree = true;
        };

        systemd.services.cuda-check = {
          wantedBy = [ "multi-user.target" ];
          path = [ pkgs.cudaPackages.saxpy ];
          script = "saxpy 2>&1";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };

        virtualisation.systemd-nspawn.options = [
          (
            if options ? testing then
              "--bind=/host/run/opengl-driver:/run/opengl-driver"
            else
              "--bind=/run/opengl-driver:/run/opengl-driver"
          )
          "--bind=/dev/dri:/dev/dri"
          "--bind=/dev/nvidia-modeset:/dev/nvidia-modeset"
          "--bind=/dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools"
          "--bind=/dev/nvidiactl:/dev/nvidiactl"
          "--bind=/dev/nvidia-uvm:/dev/nvidia-uvm"
          "--bind=/dev/nvidia0:/dev/nvidia0"
        ];
      };
  };
}
