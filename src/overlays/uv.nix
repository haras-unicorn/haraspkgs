{
  self.overlays.overlays.uv = {
    value =
      final: prev:
      let
        lib = final.lib;

        defaultCudaDeps =
          cudaPackages: with cudaPackages; [
            cudnn
            cuda_nvrtc
            nccl
            cuda_cudart
            cudatoolkit
          ];

        mkCudaEnv =
          {
            cudaPackages ? final.cudaPackages,
            cudaDeps ? defaultCudaDeps cudaPackages,
            extraDeps ? [ ],
          }:
          let
            deps = cudaDeps ++ extraDeps;
            libraryPath = final.lib.makeLibraryPath deps;
          in
          {
            inherit deps libraryPath;
            wrapArgs = ''--set LD_LIBRARY_PATH "${libraryPath}"'';
            shellHook = ''
              LD_LIBRARY_PATH="${libraryPath}"
              export LD_LIBRARY_PATH
            '';
          };

        defaultTorchIgnoreMissingDeps = [
          "libavutil.so.56"
          "libavcodec.so.58"
          "libavformat.so.58"
          "libavdevice.so.58"
          "libavfilter.so.7"
          "libavutil.so.57"
          "libavcodec.so.59"
          "libavformat.so.59"
          "libavdevice.so.59"
          "libavfilter.so.8"
        ];

        mkTorchOverrides =
          {
            cudaPackages ? final.cudaPackages,
            cudaDeps ? defaultCudaDeps cudaPackages,
            extraCudaDeps ? [ ],
            extraTorchDeps ? [ ],
            ffmpeg ? final.ffmpeg,
            sox ? final.sox,
            python ? null,
            ignoreMissingDeps ? defaultTorchIgnoreMissingDeps,
          }:
          pkgFinal: prev:
          let
            deps = cudaDeps ++ extraCudaDeps;
            sitePackages = if python != null then python.sitePackages else pkgFinal.python.sitePackages;

            torch = prev.torch.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ deps ++ extraTorchDeps;
              postFixup = (old.postFixup or "") + ''
                mkdir -p $out/lib
                for f in "$out/${sitePackages}/torch/lib"/*.so; do
                  ln -sf "$f" $out/lib/$(basename "$f")
                done
              '';
            });
          in
          {
            inherit torch;

            torchaudio = prev.torchaudio.overrideAttrs (old: {
              autoPatchelfIgnoreMissingDeps = lib.unique (
                (old.autoPatchelfIgnoreMissingDeps or [ ]) ++ ignoreMissingDeps
              );
              buildInputs =
                (old.buildInputs or [ ])
                ++ [
                  ffmpeg
                  sox
                  torch
                ]
                ++ deps;
            });

            torchtext = prev.torchtext.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ torch ];
            });

            torchvision = prev.torchvision.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ torch ] ++ deps;
            });

            xformers = prev.xformers.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ torch ] ++ deps;
            });
          };

        cudaOverrides = mkTorchOverrides { };

        mkUvLib =
          {
            uv2nix,
            pyproject-nix,
            pyproject-build-systems,
            root,
            python ? final.python3,
            envName ? "python-env",
            sourcePreference ? "wheel",
            buildSystemsOverlay ?
              pyproject-build-systems.overlays.default or pyproject-build-systems.overlays.wheel,
            pyprojectOverrides ? (_final: _prev: { }),
            packageOverrides ? (_final: _prev: { }),
            editableMembers ? [ ],
            editableRoot ? "$REPO_ROOT",
            editableOverrides ? (_final: _prev: { }),
            workspaceArgs ? { },
          }:
          let
            workspace = uv2nix.lib.workspace.loadWorkspace (
              workspaceArgs
              // {
                workspaceRoot = root;
              }
            );

            pyprojectOverlay = workspace.mkPyprojectOverlay {
              inherit sourcePreference;
            };

            basePythonSet =
              (final.callPackage pyproject-nix.build.packages {
                inherit python;
              }).overrideScope
                (
                  lib.composeManyExtensions [
                    buildSystemsOverlay
                    pyprojectOverlay
                    pyprojectOverrides
                  ]
                );

            pythonSet = basePythonSet.overrideScope packageOverrides;

            editableOverlay = workspace.mkEditablePyprojectOverlay (
              {
                root = editableRoot;
              }
              // lib.optionalAttrs (editableMembers != [ ]) {
                members = editableMembers;
              }
            );

            editablePythonSet = basePythonSet.overrideScope (
              lib.composeManyExtensions [
                editableOverlay
                editableOverrides
                packageOverrides
              ]
            );

            buildUtil = final.callPackage pyproject-nix.build.util { };
          in
          {
            inherit
              workspace
              pyprojectOverlay
              basePythonSet
              pythonSet
              editableOverlay
              editablePythonSet
              buildUtil
              python
              envName
              ;
          };

        mkPackage =
          {
            uv,
            package,
            envName ? "${package}-env",
            deps ? uv.workspace.deps.default,
          }:
          let
            venv = uv.pythonSet.mkVirtualEnv envName deps;

            application = uv.buildUtil.mkApplication {
              inherit venv;
              package = uv.pythonSet.${package};
            };
          in
          {
            inherit venv application;
          };

        mkDevShell =
          {
            uv,
            name ? "${uv.envName}-dev",
            deps ? uv.workspace.deps.all,
            packages ? [ ],
            buildInputs ? [ ],
            nativeBuildInputs ? [ ],
            env ? { },
            shellHook ? "",
            uvPackage ? final.uv,
          }:
          let
            venv = uv.editablePythonSet.mkVirtualEnv name deps;
          in
          final.mkShell {
            packages = [ venv ] ++ lib.optional (uvPackage != null) uvPackage ++ [ final.git ] ++ packages;

            inherit buildInputs nativeBuildInputs;

            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = "${venv}/bin/python";
              UV_PYTHON_DOWNLOADS = "never";
            }
            // env;

            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(${lib.getExe final.git} rev-parse --show-toplevel)
              ${shellHook}
            '';
          };
      in
      {
        uv = {
          inherit
            cudaOverrides
            defaultCudaDeps
            mkCudaEnv
            mkDevShell
            mkPackage
            mkTorchOverrides
            mkUvLib
            ;
        };
      };
  };
}
