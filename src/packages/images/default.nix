{ selfLib, ... }:

{
  self.overlays.overlays.images = {
    flake = true;
    deps = [ "podman" ];
    value =
      final: _prev:
      let
        namespace = selfLib.overlays.namespace;

        arch = final.stdenv.hostPlatform.go.GOARCH;

        images = builtins.fromJSON (builtins.readFile ./images.json);

        # Thrown lazily, so an entry without a digest or hash only fails when
        # it is built and not every evaluation of the flake.
        unpopulated =
          name:
          builtins.throw "image ${name} has no digest or ${arch} hash in images.json, get them with nix-prefetch-docker";

        pull =
          name: image:
          final.${namespace}.makePodmanImage {
            imageName = image.repository;
            imageDigest = image.digest or (unpopulated name);
            hash = image.hashes.${arch} or (unpopulated name);
            os = "linux";
            inherit arch;
            finalImageName = image.repository;
            finalImageTag = image.tag;
          };
      in
      final.lib.mapAttrs' (name: image: final.lib.nameValuePair "image-${name}" (pull name image)) images;
  };
}
