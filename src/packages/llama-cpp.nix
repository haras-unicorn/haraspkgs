{
  self.overlays.overlays.llama-cpp = {
    flake = true;
    value =
      final: prev:
      let
        python = final.python3.withPackages (ps: [
          ps.numpy
          ps.sentencepiece
          ps.transformers
          ps.protobuf
          ps.torch
        ]);
      in
      {
        llama-cpp-convert = final.stdenvNoCC.mkDerivation {
          pname = "llama-cpp-convert";
          inherit (final.llama-cpp) version;
          src = final.llama-cpp.src;

          nativeBuildInputs = [ final.makeWrapper ];

          dontConfigure = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib $out/bin
            cp -r conversion gguf-py convert_hf_to_gguf.py $out/lib/

            makeWrapper ${python}/bin/python3 $out/bin/llama-convert-hf-to-gguf \
              --add-flags "$out/lib/convert_hf_to_gguf.py" \
              --prefix PYTHONPATH : "$out/lib:$out/lib/gguf-py"

            runHook postInstall
          '';

          meta = {
            description = "Convert HuggingFace checkpoints to GGUF (llama.cpp)";
            homepage = "https://github.com/ggml-org/llama.cpp";
            license = final.lib.licenses.mit;
            mainProgram = "llama-convert-hf-to-gguf";
          };
        };
      };
  };
}
