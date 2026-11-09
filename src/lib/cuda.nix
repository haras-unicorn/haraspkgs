# NOTE: https://applicative.systems/nixos-test-driver-manual/tutorials/cuda-tests

{
  self.lib.cuda = {
    flake = true;

    hostModule = { lib, pkgs, ... }: {
      programs.nix-required-mounts = lib.mkIf pkgs.config.cudaSupport {
        enable = true;
        presets.nvidia-gpu.enable = true;
      };

      hardware.nvidia-container-toolkit.enable = lib.mkIf pkgs.config.cudaSupport true;
    };

    testModule = {
      requiredFeatures = {
        cuda = true;
        nvidia-gpu = true;
      };
    };

    guestModule =
      {
        lib,
        options,
        ...
      }:
      {
        # With a read-only package set, as in a test that sets `node.pkgs`, the
        # package set is already the one the guest is meant to have, and
        # NixOS rejects any other definition of the config.
        nixpkgs.config = lib.mkIf (!options.nixpkgs.pkgs.isDefined) {
          cudaSupport = true;
          allowUnfree = true;
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
