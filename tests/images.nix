{
  perSystem =
    { lib, pkgs, ... }:
    let
      images = lib.filterAttrs (name: _: lib.hasPrefix "image-" name) pkgs.harasPackages;

      # Exporting the container reads its root file system through the overlay
      # mount, so it fails when the layers did not unpack. The images are
      # official, so what they do once running is not tested here.
      check =
        name: image:
        pkgs.harasPackages.withPodman (
          pkgs.runCommand "haraspkgs-${name}-check"
            {
              nativeBuildInputs = [ pkgs.gnutar ];
              podmanImages = [ image ];
            }
            ''
              reference="$(podman --remote images --noheading \
                --format '{{.Repository}}:{{.Tag}}')"
              container="$(podman --remote create "$reference")"
              podman --remote export "$container" | tar --list > /dev/null
              touch "$out"
            ''
        );
    in
    {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (builtins.mapAttrs check images);
    };
}
