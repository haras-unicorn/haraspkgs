{
  self.overlays.overlays.docs = {
    flake = true;
    value = final: prev: {
      mkMdbook =
        {
          name ? "docs",
          src,
          book ? "${src}/docs",
        }:
        final.runCommand name
          {
            nativeBuildInputs = [ final.mdbook ];
          }
          ''
            mdbook build -d "$out" "${book}"
          '';

      mkOptionsDocs =
        {
          name ? "options.md",
          modules,
          specialArgs ? { },
          transformOptions ? final.lib.id,
        }:
        let
          evaluated = final.lib.evalModules {
            inherit modules specialArgs;
          };

          optionsDoc = final.nixosOptionsDoc {
            options = evaluated.options;
            inherit transformOptions;
          };
        in
        {
          inherit name;
          inherit (optionsDoc) optionsCommonMark;
        };
    };
  };
}
