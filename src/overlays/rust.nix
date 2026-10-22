{
  self.overlays.overlays.rust = {
    value =
      final: prev:
      let
        lib = final.lib;

        mkRustToolchain =
          {
            rustOverlay,
            channel ? "stable",
            targets ? [ ],
            components ? [
              "rustfmt"
              "clippy"
              "rust-analyzer"
            ],
          }:
          let
            rustBin = rustOverlay.lib.mkRustBin { } final;

            base =
              if channel == "stable" then
                rustBin.stable.latest.default
              else if channel == "beta" then
                rustBin.beta.latest.default
              else if channel == "nightly" then
                rustBin.selectLatestNightlyWith (toolchain: toolchain.default)
              else
                rustBin.stable.${channel}.default;
          in
          base.override {
            extensions = components;
            inherit targets;
          };

        mkCraneLib =
          {
            crane,
            toolchain,
          }:
          (crane.mkLib final).overrideToolchain (_: toolchain);

        mkRustPackage =
          {
            craneLib,
            src,
            pname,
            version,
            crate ? null,
            features ? [ ],
            cargoExtraArgs ? [ ],
            nativeBuildInputs ? [ ],
            env ? { },
            buildInputs ? [ ],
            strictDeps ? true,
            mainProgram ? pname,
            meta ? { },
          }:
          let
            cleanedSrc = craneLib.cleanCargoSource src;

            cargoArgs =
              (lib.optional (crate != null) "-p ${crate}")
              ++ (lib.optional (features != [ ]) "--features ${lib.concatStringsSep "," features}")
              ++ (if builtins.isList cargoExtraArgs then cargoExtraArgs else [ cargoExtraArgs ]);

            cargoExtraArgs' = lib.concatStringsSep " " (builtins.filter (arg: arg != "") cargoArgs);

            commonArgs = {
              inherit
                pname
                version
                nativeBuildInputs
                buildInputs
                env
                strictDeps
                ;
              src = cleanedSrc;
            }
            // lib.optionalAttrs (cargoExtraArgs' != "") {
              cargoExtraArgs = cargoExtraArgs';
            };

            cargoVendorDir = craneLib.vendorCargoDeps { src = cleanedSrc; };

            depsOnly = craneLib.buildDepsOnly (commonArgs // { inherit cargoVendorDir; });

            unwrapped = craneLib.buildPackage (
              commonArgs
              // {
                cargoArtifacts = depsOnly;
                inherit cargoVendorDir;
                meta = meta // {
                  inherit mainProgram;
                };
              }
            );
          in
          {
            inherit depsOnly unwrapped;
          };
      in
      {
        rust = {
          inherit
            mkCraneLib
            mkRustPackage
            mkRustToolchain
            ;
        };
      };
  };
}
