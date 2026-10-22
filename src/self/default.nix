{ selfLib, ... }:

{
  self.devShells.default = {
    flake = true;
    value =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        yaml = pkgs.formats.yaml { };

        toml = pkgs.formats.toml { };

        json = pkgs.formats.json { };

        namespace = selfLib.overlays.namespace;

        prettierConfig = yaml.generate "prettier.yaml" {
          printWidth = 80;
          tabWidth = 2;
          useTabs = false;
          trailingComma = "all";
          endOfLine = "lf";
          proseWrap = "always";
        };

        cspellRoot = yaml.generate "cspell.yaml" {
          useGitignore = true;
          version = "0.2";
          language = "en";
          ignorePaths = [ "CHANGELOG.md" ];
          words = [
            "autologin"
            "chdir"
            "cmdline"
            "esac"
            "gcroots"
            "journalctl"
            "shellcheck"
            "shfmt"
            "shlex"
            "SIGRTMIN"
            "splitlines"
            "Accio"
            "amdgpu"
            "appimage"
            "archs"
            "binutils"
            "cccl"
            "coreutils"
            "cubin"
            "cublas"
            "cufft"
            "cufile"
            "cupti"
            "curand"
            "cusolver"
            "cusparse"
            "cusparselt"
            "DCMAKE"
            "DCUDA"
            "DLLAMA"
            "DSTRATA"
            "flashinfer"
            "fopen"
            "ggml"
            "GGML"
            "libcublas"
            "LIBCUDA"
            "libcudart"
            "libcufile"
            "libtorch"
            "Niko"
            "numba"
            "nvcc"
            "nvjitlink"
            "nvshmem"
            "nvtx"
            "psutil"
            "pyyaml"
            "RDMA"
            "Runpath"
            "sglang"
            "Sglang"
            "socat"
            "spawnp"
            "tqdm"
            "virtualenv"
            "anythingllm"
            "attrset"
            "attrsets"
            "barebones"
            "bitburner"
            "bitripper"
            "bubblewrap"
            "bwrap"
            "cachix"
            "clippy"
            "comfyui"
            "cooldown"
            "cristo"
            "cryl"
            "ctdb"
            "cuda"
            "cudart"
            "cudatoolkit"
            "cudnn"
            "deadnix"
            "Diátaxis"
            "direnv"
            "downloaders"
            "dont"
            "envrc"
            "facter"
            "fahhh"
            "fetchgguf"
            "fetchhf"
            "fetchurl"
            "footguns"
            "foldl"
            "freetoken"
            "gemma"
            "gguf"
            "gles"
            "GSYNC"
            "gutenberg"
            "haras"
            "haraspkgs"
            "hasanabi"
            "huggingface"
            "inplace"
            "ipetkov"
            "ISTA"
            "jammin"
            "langservers"
            "libavcodec"
            "libavdevice"
            "libavfilter"
            "libavformat"
            "libavutil"
            "LIBVA"
            "ltrimstr"
            "lule"
            "lulezojne"
            "mapx"
            "markdownignore"
            "mdbook"
            "miniflux"
            "mkflake"
            "mktemp"
            "miserables"
            "mmap"
            "mmproj"
            "moby"
            "modeset"
            "modesetting"
            "naersk"
            "nccl"
            "niri"
            "nixfmt"
            "nixos"
            "nixpkgs"
            "nspawn"
            "nvidiactl"
            "nvim"
            "nvrtc"
            "numpy"
            "occamy"
            "oneshot"
            "optimus"
            "outtype"
            "oxalica"
            "Pandoc"
            "passthru"
            "patchelf"
            "pipefail"
            "pkgs"
            "pname"
            "pyproject"
            "PYTHONPATH"
            "quantizer"
            "rocm"
            "rustc"
            "qwen"
            "sandboxing"
            "saxpy"
            "sdist"
            "searchkit"
            "sentencepiece"
            "setuptools"
            "stdenv"
            "strata"
            "substituters"
            "sysfs"
            "taplo"
            "tmpfs"
            "toplevel"
            "torchaudio"
            "torchtext"
            "torchvision"
            "treefmt"
            "ubatch"
            "unsets"
            "vaultwarden"
            "venv"
            "VDPAU"
            "virtualisation"
            "worktree"
            "xformers"
            "yq"
            "zeroclaw"
          ];
        };

        cspellSrc = yaml.generate "cspell.yaml" {
          useGitignore = true;
          version = "0.2";
          language = "en";
          words = [ "uids" ];
        };

        markdownlintConfig = json.generate "markdownlint.json" {
          "$schema" =
            "https://raw.githubusercontent.com/DavidAnson/markdownlint/main/schema/markdownlint-config-schema.json";
        };

        markdownLinkCheckConfig = json.generate "markdown-link-check.json" (
          builtins.toJSON {
            ignorePatterns = [
              { pattern = "^#"; }
              { pattern = "^https://localhost"; }
              { pattern = "^http://localhost"; }
              { pattern = "^https://haras-unicorn.github.io/haraspkgs"; }
              { pattern = "^https://github.com/haras-unicorn/haraspkgs"; }
            ];
          }
        );

        helixServers = lib.mapAttrs (
          _: server:
          {
            inherit (server) command;
          }
          // lib.optionalAttrs (server.arguments != [ ]) {
            args = server.arguments;
          }
          // lib.optionalAttrs (server.config != { }) {
            inherit (server) config;
          }
        ) config.languages.servers;

        helixLanguages = lib.mapAttrsToList (
          name: language:
          {
            inherit name;
            auto-format = language.auto-format;
          }
          // lib.optionalAttrs (language.servers != [ ]) {
            language-servers = language.servers;
          }
          // lib.optionalAttrs (language.formatter != null) {
            formatter = {
              inherit (language.formatter) command;
            }
            // lib.optionalAttrs (language.formatter.arguments != [ ]) {
              args = language.formatter.arguments;
            };
          }
        ) config.languages.languages;

        helixLanguagesToml = toml.generate "languages.toml" (
          lib.optionalAttrs (helixServers != { }) {
            language-server = helixServers;
          }
          // lib.optionalAttrs (helixLanguages != [ ]) {
            language = helixLanguages;
          }
        );

        nixfmtWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "nixfmt";
          package = pkgs.nixfmt;
        };

        prettierWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "prettier";
          package = pkgs.prettier;
        };

        taploWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "taplo";
          package = pkgs.taplo;
        };

        cspellWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "cspell";
          package = pkgs.cspell;
        };

        shfmtWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "shfmt";
          package = pkgs.shfmt;
        };

        tidyWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "tidy";
          package = pkgs.html-tidy;
        };

        hxWrapped = pkgs.${namespace}.makeBubblewrapWrapper {
          name = "hx";
          package = pkgs.helix;
          files = {
            "~/.cache/helix" = {
              mode = "rw";
            };
            ".helix/languages.toml" = {
              mode = "ro";
              source = helixLanguagesToml;
            };
          };
        };

        external = with pkgs; [
          nil
          nix-unit
          nix

          bash-language-server
          nushell
          fd
          mdbook

          yaml-language-server
          vscode-langservers-extracted
          markdownlint-cli
          markdown-link-check
          marksman
          treefmt
        ];
      in
      {
        packages = [
          pkgs.${namespace}.flake-root
          nixfmtWrapped
          prettierWrapped
          taploWrapped
          cspellWrapped
          hxWrapped
          shfmtWrapped
          tidyWrapped
        ]
        ++ external;

        bwrap.files = {
          "cspell.yaml".source = cspellRoot;
          "src/cspell.yaml".source = cspellSrc;
        };

        git = {
          enable = true;
          ignore = {
            templates = [ "Nix" ];
            patterns = ''
              # Repository

              .env
              docs/book
            '';
          };
          attributes = ''
            * text=auto eol=lf
          '';
        };

        editorconfig = {
          enable = true;
          settings."*" = {
            end_of_line = "lf";
            charset = "utf-8";
            max_line_length = 80;
            indent_style = "space";
            indent_size = 2;
            tab_width = 2;
            insert_final_newline = true;
            trim_trailing_whitespace = true;
          };
        };

        languages = {
          servers = {
            nil.command = "nil";

            bash-language-server = {
              command = "bash-language-server";
              arguments = [ "start" ];
            };

            taplo = {
              command = "taplo";
              arguments = [
                "lsp"
                "stdio"
              ];
            };

            yaml-language-server = {
              command = "yaml-language-server";
              arguments = [ "--stdio" ];
            };

            marksman = {
              command = "marksman";
              arguments = [ "server" ];
            };

            nu-lsp = {
              command = "nu";
              arguments = [ "--lsp" ];
            };

            vscode-json-language-server = {
              command = "vscode-json-language-server";
              arguments = [ "--stdio" ];
              config = {
                provideFormatter = true;
                format.enable = true;
                json.validate.enable = true;
              };
            };
          };

          languages = {
            nix = {
              servers = [ "nil" ];
              formatter = {
                command = lib.getExe pkgs.nixfmt;
                arguments = [
                  "--filename"
                  "%{buffer_name}"
                ];
              };
            };

            bash = {
              servers = [ "bash-language-server" ];
              formatter.command = lib.getExe pkgs.shfmt;
            };

            toml.servers = [ "taplo" ];

            yaml = {
              servers = [ "yaml-language-server" ];
              formatter = {
                command = lib.getExe pkgs.prettier;
                arguments = [
                  "--config"
                  (builtins.toString prettierConfig)
                  "--parser"
                  "yaml"
                ];
              };
            };

            json = {
              servers = [ "vscode-json-language-server" ];
              formatter = {
                command = lib.getExe pkgs.prettier;
                arguments = [
                  "--config"
                  (builtins.toString prettierConfig)
                  "--parser"
                  "json"
                ];
              };
            };

            markdown = {
              servers = [ "marksman" ];
              formatter = {
                command = lib.getExe pkgs.prettier;
                arguments = [
                  "--config"
                  (builtins.toString prettierConfig)
                  "--parser"
                  "markdown"
                ];
              };
            };

            xml.formatter = {
              command = lib.getExe pkgs.html-tidy;
              arguments = [
                "-xml"
                "-i"
              ];
            };

            nu.servers = [ "nu-lsp" ];
          };
        };

        license = {
          enable = true;
          spdx = "MIT";
          path = "LICENSE.md";
          attrs = {
            "<year>" = "2026";
            "<copyright holders>" = "github@haras-unicorn.net";
          };
        };

        codeOfConduct.contributorCovenant = {
          enable = true;
          path = "CODE_OF_CONDUCT.md";
        };

        cli.commands = {
          docs = {
            description = "Build the documentation.";
            packages = [ pkgs.nix ];
            commands = ''nix build ".#docs" --no-link --print-out-paths'';
          };

          check-links = {
            description = "Check Markdown links.";
            packages = [
              pkgs.fd
              pkgs.markdown-link-check
            ];
            commands = ''
              fd --glob '**/*.md' . -0 | xargs -0 -r markdown-link-check \
                --config ${markdownLinkCheckConfig} \
                --quiet
            '';
          };
        };

        workflows = {
          check = {
            on = {
              pull_request = { };
              push.branches = [ "main" ];
            };

            matrix.os = [
              "ubuntu-latest"
              "macos-latest"
            ];

            installable = null;

            steps = [
              { run = "nix flake check --all-systems --show-trace"; }
              { run = "nix build --show-trace .#docs"; }
            ];
          };

          docs = {
            on.push.branches = [ "main" ];

            permissions = {
              contents = "read";
              "id-token" = "write";
              pages = "write";
            };

            installable = ".#docs";

            steps = [
              {
                uses = "actions/upload-pages-artifact@v3";
                "with".path = "./result";
              }
              { uses = "actions/deploy-pages@v4"; }
            ];
          };

          release = {
            on.push.branches = [ "main" ];

            permissions = {
              contents = "write";
              "pull-requests" = "write";
            };

            installable = null;
            installNix = false;
            cachix = null;

            steps = [
              {
                uses = "googleapis/release-please-action@v4";
                "with" = {
                  command = "manifest";
                  token = "\${{ secrets.RELEASE_PLEASE_TOKEN }}";
                  "config-file" = ".release-please-config.json";
                  "manifest-file" = ".release-please-manifest.json";
                  "default-branch" = "main";
                };
              }
            ];
          };
        };

        check.checks = {
          cspell = {
            packages = [ cspellWrapped ];
            commands = "cspell lint . --no-progress";
          };

          markdownlint = {
            packages = [
              pkgs.markdownlint-cli
            ];
            commands = ''
              markdownlint --config ${markdownlintConfig} --ignore-path .gitignore --ignore CHANGELOG.md --ignore LICENSE.md .
            '';
          };

          nil = {
            packages = [
              pkgs.fd
              pkgs.nil
            ];
            commands = "fd --glob '*.nix' . -0 | xargs -0 -r nil diagnostics";
          };
        };

        format.formatters = {
          nixfmt = {
            packages = [ nixfmtWrapped ];
            command = "nixfmt";
            includes = [ "*.nix" ];
          };

          taplo = {
            packages = [ taploWrapped ];
            command = "taplo";
            options = [ "format" ];
            includes = [ "*.toml" ];
          };

          prettier = {
            packages = [ prettierWrapped ];
            command = "prettier";
            options = [
              "--write"
              "--config"
              (builtins.toString prettierConfig)
            ];
            includes = [
              "*.json"
              "*.md"
              "*.yaml"
              "*.yml"
            ];
            excludes = [
              "flake.lock"
              ".release-please-manifest.json"
              "CHANGELOG.md"
              "LICENSE.md"
            ];
          };
        };
      };
  };
}
