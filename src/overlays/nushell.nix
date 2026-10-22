{
  self.overlays.overlays.nushell = {
    flake = true;
    value = final: prev: {
      writeNushellApplication =
        {
          name,
          runtimeInputs ? [ ],
          text ? "",
          environment ? { },
        }:
        let
          path = builtins.concatStringsSep "\n        " (
            builtins.map (input: "\"${input}/bin\"") runtimeInputs
          );
          envLines = builtins.concatStringsSep "\n        " (
            final.lib.mapAttrsToList (
              key: value: "$env.${key} = ${builtins.toJSON (toString value)}"
            ) environment
          );

          wrapped = final.writeText "${name}.nu" ''
            #!${final.lib.getExe final.nushell}

            export-env {
              $env.PATH ++= [
                ${path}
              ]
              ${envLines}
            }

            ${text}
          '';
        in
        final.runCommand name
          {
            nativeBuildInputs = [ final.nushell ];
            meta.mainProgram = name;
          }
          ''
            nu --commands "nu-check --debug ${wrapped}"
            mkdir -p $out/bin
            install -m755 ${wrapped} $out/bin/${name}
          '';
    };
  };
}
