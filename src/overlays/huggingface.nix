{
  self.overlays.overlays.huggingface = {
    flake = true;
    value = final: prev: {
      fetchhf =
        {
          name,
          repo,
          rev ? "main",
          hash ? final.lib.fakeHash,
          passthru ? { },
        }:
        let
          model = final.stdenvNoCC.mkDerivation {
            inherit name;

            nativeBuildInputs = [
              (final.python3.withPackages (ps: [ ps.huggingface-hub ]))
              final.cacert
            ];

            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
            outputHash = hash;

            buildCommand = ''
              export HOME="$TMPDIR"
              export SSL_CERT_FILE="${final.cacert}/etc/ssl/certs/ca-bundle.crt"
              hf download ${repo} \
                --revision ${rev} \
                --local-dir "$out"
              rm -rf "$out/.cache"
            '';
          };

          config = final.lib.importJSON "${model}/config.json";
        in
        model
        // {
          passthru = {
            inherit
              name
              repo
              rev
              config
              ;
            modelName = config._name_or_path or name;
            modelType = config.model_type or null;
            architectures = config.architectures or [ ];
            contextLength = config.max_position_embeddings or null;
          }
          // passthru;
        };

      fetchgguf =
        {
          name,
          repo,
          rev ? "main",
          include,
          hash ? final.lib.fakeHash,
          passthru ? { },
        }:
        let
          model = final.stdenvNoCC.mkDerivation {
            inherit name;

            nativeBuildInputs = [
              (final.python3.withPackages (ps: [ ps.huggingface-hub ]))
              final.cacert
            ];

            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
            outputHash = hash;

            buildCommand = ''
              export HOME="$TMPDIR"
              export SSL_CERT_FILE="${final.cacert}/etc/ssl/certs/ca-bundle.crt"
              hf download ${repo} \
                --revision ${rev} \
                ${
                  final.lib.concatStringsSep " " (
                    map (pattern: "--include ${final.lib.escapeShellArg pattern}") include
                  )
                } \
                --local-dir "$out"
              rm -rf "$out/.cache"
            '';
          };
        in
        model
        // {
          passthru = {
            inherit
              name
              repo
              rev
              include
              ;
          }
          // passthru;
        };
    };
  };
}
