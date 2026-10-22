{
  self.overlays.overlays.pnpm = {
    value =
      final: prev:
      let
        lib = final.lib;

        mkPnpmPackage =
          {
            src,
            pname,
            version,
            pnpmDeps,
            node ? final.nodejs_24,
            pnpm ? final.pnpm_9,
            buildPhase ? null,
            installPhase ? null,
            nativeBuildInputs ? [ ],
            buildInputs ? [ ],
            meta ? { },
            ...
          }@args:
          let
            extraAttrs = removeAttrs args [
              "src"
              "pname"
              "version"
              "pnpmDeps"
              "node"
              "pnpm"
              "buildPhase"
              "installPhase"
              "nativeBuildInputs"
              "buildInputs"
              "meta"
            ];
          in
          final.stdenv.mkDerivation (
            {
              inherit
                src
                pname
                version
                pnpmDeps
                buildInputs
                meta
                ;

              nativeBuildInputs = [
                final.pnpmConfigHook
                node
                pnpm
              ]
              ++ nativeBuildInputs;
            }
            // lib.optionalAttrs (buildPhase != null) { inherit buildPhase; }
            // lib.optionalAttrs (installPhase != null) { inherit installPhase; }
            // extraAttrs
          );

        mkPnpmWorkspace =
          {
            src,
            pname,
            version,
            hash,
            fetcherVersion ? 3,
            node ? final.nodejs_24,
            pnpm ? final.pnpm_9,
            nativeBuildInputs ? [ ],
            buildInputs ? [ ],
          }:
          let
            pnpmDeps = final.fetchPnpmDeps {
              inherit
                pname
                version
                src
                hash
                fetcherVersion
                pnpm
                ;
            };

            nodeModules = final.stdenv.mkDerivation {
              pname = "${pname}-node-modules";
              inherit version src pnpmDeps;

              nativeBuildInputs = [
                final.autoPatchelfHook
                final.jq
                final.pnpmConfigHook
                pnpm
                node
              ]
              ++ nativeBuildInputs;

              buildInputs = [ final.stdenv.cc.cc.lib ] ++ buildInputs;

              buildPhase = ''
                pnpm install --offline --frozen-lockfile
              '';

              installPhase = ''
                mkdir -p $out/lib
                mkdir -p $out/bin

                pnpm ls -r --depth -1 --json > pkgs.json

                jq -r '.[].path' pkgs.json | while read -r path; do
                  rel="''${path#$PWD}"
                  mkdir -p "$out/lib/$rel"
                  mkdir -p "$path/node_modules"
                  cp -R "$path/node_modules" "$out/lib/$rel"

                  for f in "$out/lib/$rel/node_modules/.bin"/*; do
                    [ -e "$f" ] || continue
                    name=$(basename "$f")
                    {
                      printf '%s\n' '#!/usr/bin/env bash'
                      printf 'export NODE_PATH="%s"\n' "$out/lib/$rel/node_modules"
                      printf 'exec "%s" "$@"\n' "$f"
                    } > "$out/bin/$name"
                    chmod +x "$out/bin/$name"
                  done
                done

                jq \
                  --arg root "$PWD" \
                  'map(.path |= ltrimstr($root))' \
                  pkgs.json > $out/pkgs.json
              '';
            };

            symlinkNodeModules = final.writeShellApplication {
              name = "symlink-node-modules";
              runtimeInputs = [
                final.git
                final.jq
              ];
              text = ''
                root=$(git rev-parse --show-toplevel)
                jq -r '.[].path' '${nodeModules}/pkgs.json' \
                  | while read -r path; do
                  src="${nodeModules}/lib$path/node_modules"
                  dest="$root$path/node_modules"
                  rm -fr "$dest"
                  ln -s "$src" "$dest"
                done
              '';
            };

            pnpmWithReload = final.writeShellApplication {
              name = "pnpm-with-reload";
              runtimeInputs = [
                pnpm
                final.direnv
                final.jq
                final.git
              ];
              text = ''
                root=$(git rev-parse --show-toplevel)
                jq -r '.[].path' '${nodeModules}/pkgs.json' \
                  | while read -r path; do
                  dest="$root$path/node_modules"
                  rm -fr "$dest"
                done
                pnpm "$@"
                direnv reload .
              '';
            };

            shellHook = "${symlinkNodeModules}/bin/symlink-node-modules";

            devShell = final.mkShell {
              packages = [
                nodeModules
                node
                pnpm
                symlinkNodeModules
                pnpmWithReload
              ];
              inherit shellHook;
            };
          in
          {
            inherit
              node
              pnpm
              pnpmDeps
              nodeModules
              symlinkNodeModules
              pnpmWithReload
              shellHook
              devShell
              ;

            mkPackage =
              package:
              mkPnpmPackage (
                {
                  inherit
                    src
                    pnpmDeps
                    node
                    pnpm
                    ;
                }
                // package
              );
          };
      in
      {
        pnpm = {
          inherit
            mkPnpmPackage
            mkPnpmWorkspace
            ;
        };
      };
  };
}
