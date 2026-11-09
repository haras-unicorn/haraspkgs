{
  self.overlays.overlays.mustache = {
    flake = true;
    value =
      final: _prev:
      let
        renderMustache =
          {
            name,
            text,
            vars ? { },
          }:
          let
            template = final.writeText "${name}-template" text;
            data = final.writeText "${name}-vars.json" (builtins.toJSON vars);
          in
          final.runCommand name { nativeBuildInputs = [ final.mustache-go ]; } ''
            mustache --allow-missing-variables=false ${data} ${template} > "$out"
          '';

        renderMustacheText = args: builtins.readFile (renderMustache args);
      in
      {
        inherit renderMustache renderMustacheText;
      };
  };
}
