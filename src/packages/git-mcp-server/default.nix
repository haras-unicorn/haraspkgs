{
  selfLib,
  inputs,
  ...
}:

{
  self.overlays.overlays.git-mcp-server = {
    flake = true;
    value =
      final: prev:
      let
        lib = final.lib;

        system = final.stdenv.hostPlatform.system;

        bun2nixFlake = (if inputs ? bun2nix then inputs else selfLib.lib.inputs).bun2nix;

        bun2nix = bun2nixFlake.packages.${system}.default;

        # NOTE: fetch git because fetchFromGitHub doesn't download tsconfig.json
        src = final.fetchgit {
          url = "https://github.com/cyanheads/git-mcp-server";
          # NOTE: v2.15.1
          rev = "31dd1918500a51129f0a086ed3471527961c7572";
          hash = "sha256-zJdkkEbmXMHHnj1ISMTeUVpARL7t5RVhOnm1PIfjOqg=";
        };

        gitMcpServer = bun2nix.mkDerivation {
          inherit src;

          packageJson = "${src}/package.json";

          pname = "git-mcp-server";
          version = "2.15.1";

          bunDeps = bun2nix.fetchBunDeps {
            bunNix = ./default.nix.lock;
          };

          nativeBuildInputs = [
            final.makeWrapper
          ];

          dontRunLifecycleScripts = true;

          buildPhase = ''
            bun run build
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/git-mcp-server $out/bin
            cp -r dist $out/lib/git-mcp-server/dist
            cp -r node_modules $out/lib/git-mcp-server/node_modules

            makeWrapper ${lib.getExe final.bun} $out/bin/git-mcp-server \
              --prefix PATH : ${
                lib.makeBinPath [
                  final.git
                  final.openssh
                ]
              } \
              --argv0 git-mcp-server \
              --add-flags "$out/lib/git-mcp-server/dist/index.js"

            runHook postInstall
          '';
        };

        gitMcpServerBwrap = final.callPackage (
          {
            bwrapArgs ? null,
          }:
          final.writeShellApplication {
            name = "git-mcp-server-bwrap";
            runtimeInputs = [ final.bubblewrap ];
            text = ''
              mkdir -p "$GIT_BASE_DIR"
              mkdir -p "$GIT_SSH_DIR"
              exec bwrap \
                ${lib.escapeShellArgs (if bwrapArgs != null then bwrapArgs else selfLib.bwrap.network)} \
                --bind "$GIT_BASE_DIR" "$GIT_BASE_DIR" \
                --bind "$GIT_SSH_DIR" "$GIT_SSH_DIR" \
                --chdir "$GIT_BASE_DIR" \
                --setenv HOME "$GIT_BASE_DIR" \
                -- ${lib.getExe gitMcpServer} "$GIT_BASE_DIR" "$@"
            '';
            meta = {
              description = "Git MCP Server wrapped with bubblewrap";
              mainProgram = "git-mcp-server-bwrap";
            };
          }
        ) { };

        gitMcpServerSshCommand = final.writeShellApplication {
          name = "git-mcp-server-ssh-command";
          runtimeInputs = [ final.openssh ];
          text = ''
            mkdir -p "$GIT_SSH_DIR"
            exec ssh \
              -o "StrictHostKeyChecking=accept-new" \
              -o "UserKnownHostsFile=$GIT_SSH_DIR/known_hosts" \
              "$@"
          '';
        };

        gitMcpServerSshAgent = final.callPackage (
          {
            bwrapArgs ? null,
          }:
          let
            gitMcpServerAddSshKey = final.writeShellApplication {
              name = "git-mcp-server-add-ssh-key";
              runtimeInputs = [
                final.openssh
                (gitMcpServerBwrap.override { inherit bwrapArgs; })
              ];
              text = ''
                printf "%s" "$GIT_SSH_KEY" | sed 's/\\n/\n/g' | ssh-add -
                unset GIT_SSH_KEY
                exec git-mcp-server-bwrap "$@"
              '';
            };
          in
          final.writeShellApplication {
            name = "git-mcp-server-ssh-agent";
            runtimeInputs = [
              final.openssh
              gitMcpServerAddSshKey
            ];
            text = ''
              export GIT_SSH_COMMAND="${lib.getExe gitMcpServerSshCommand}"
              mkdir -p "$GIT_SSH_DIR"
              rm -f "$GIT_SSH_DIR/agent.sock"
              ssh-agent -D -a "$GIT_SSH_DIR/agent.sock" &
              SSH_AGENT_PID=$!
              export SSH_AUTH_SOCK="$GIT_SSH_DIR/agent.sock"
              cleanup() { kill "$SSH_AGENT_PID" 2>/dev/null || true; }
              trap cleanup EXIT
              trap 'exit 143' TERM
              trap 'exit 130' INT
              for _ in $(seq 1 50); do
                [ -S "$SSH_AUTH_SOCK" ] && break
                kill -0 "$SSH_AGENT_PID" 2>/dev/null || break
                sleep 0.1
              done
              git-mcp-server-add-ssh-key "$@"
            '';
            meta = {
              description = "Git MCP Server wrapped with an SSH agent and bubblewrap";
              mainProgram = "git-mcp-server-ssh-agent";
            };
          }
        ) { };
      in
      {
        git-mcp-server = gitMcpServer;
      }
      // final.lib.optionalAttrs final.stdenv.isLinux {
        git-mcp-server-bwrap = gitMcpServerBwrap;
        git-mcp-server-ssh-agent = gitMcpServerSshAgent;
      };
  };
}
