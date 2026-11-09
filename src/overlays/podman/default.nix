{
  self.overlays.overlays.podman = {
    flake = true;
    value =
      final: _prev:
      let
        # Shared by both helpers, so they wait the same time unless told
        # otherwise.
        defaultStartTimeout = 10;

        defaultCuda = final.config.cudaSupport or false;

        toml = final.formats.toml { };

        policy = final.writeText "policy.json" (
          builtins.toJSON {
            default = [ { type = "insecureAcceptAnything"; } ];
          }
        );

        storageConf = toml.generate "storage.conf" {
          storage = {
            driver = "overlay";
            graphroot = "__STATE__/root";
            runroot = "__STATE__/run/containers";
            options.overlay.mountopt = "nodev,userxattr";
          };
        };

        containersConf = toml.generate "containers.conf" {
          containers = {
            netns = "bridge";
            cgroups = "disabled";
          };
          network = {
            network_backend = "netavark";
            network_config_dir = "__STATE__/networks";
          };
          engine = {
            cgroup_manager = "cgroupfs";
            events_logger = "file";
            cdi_spec_dirs = [ "__STATE__/cdi" ];
          };
        };

        makeSandbox =
          { cuda }:
          let
            toolkit = final.nvidia-container-toolkit;

            inputs = [
              final.coreutils
              final.gnused
              final.iproute2
              final.nftables
              final.podman
              final.docker-client
              final.util-linux
            ]
            ++ final.lib.optional cuda toolkit;

            file = final.replaceVars ./sandbox.bash {
              policy = builtins.toString policy;
              storageConf = builtins.toString storageConf;
              containersConf = builtins.toString containersConf;
              cdiHook = final.lib.optionalString cuda "${final.lib.getOutput "tools" toolkit}/bin/nvidia-cdi-hook";
              ldconfig = final.lib.optionalString cuda (final.lib.getExe' final.glibc "ldconfig");
            };
          in
          {
            inherit inputs file;
          };

        # The Nix build sandbox filters chmod calls that set setuid or setgid
        # bits, which makes the daemon fail to unpack the layers of images that
        # have such files (most images built on a distribution). The bits do
        # not matter in a test, so they are cleared and the layer and config
        # digests rewritten to match.
        stripSetuid =
          image:
          final.runCommand image.name { nativeBuildInputs = [ final.python3 ]; } ''
            python3 -I ${./strip-setuid.py} ${image} "$out"
          '';

        toImageList = images: final.lib.concatMapStringsSep " " builtins.toString images;

        defaultSandbox = makeSandbox { cuda = defaultCuda; };

        hook =
          final.makeSetupHook
            {
              name = "podman-sandbox-hook";
              propagatedBuildInputs = defaultSandbox.inputs;
            }
            (
              final.writeText "podman-sandbox-hook.sh" ''
                : "''${PODMAN_SANDBOX_START_TIMEOUT:=${builtins.toString defaultStartTimeout}}"
                export PODMAN_SANDBOX_START_TIMEOUT
                source ${defaultSandbox.file}
                postHooks+=(startPodmanSandbox)
                failureHooks+=(dumpPodmanSandboxLog)
              ''
            );
      in
      {
        makePodmanImage = args: stripSetuid (final.dockerTools.pullImage args);

        makePodmanScript =
          {
            name,
            text,
            runtimeInputs ? [ ],
            startTimeout ? defaultStartTimeout,
            cuda ? defaultCuda,
            images ? [ ],
          }:
          let
            sandbox = makeSandbox { inherit cuda; };
          in
          final.writeShellApplication {
            inherit name;
            runtimeInputs = runtimeInputs ++ sandbox.inputs;
            text = ''
              export PODMAN_SANDBOX_START_TIMEOUT=${builtins.toString startTimeout}
              export PODMAN_SANDBOX_IMAGES=${final.lib.escapeShellArg (toImageList images)}
              # shellcheck source=/dev/null
              source ${sandbox.file}
              startPodmanSandbox
              trap stopPodmanSandbox EXIT
              ${text}
            '';
          };

        # Images come from the `podmanImages` attribute of the derivation, so
        # they are build inputs like any other and need no new calling form.
        withPodman =
          derivation:
          derivation.overrideAttrs (old: {
            PODMAN_SANDBOX_IMAGES = toImageList (old.podmanImages or [ ]);
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ hook ];
            requiredSystemFeatures = final.lib.unique ((old.requiredSystemFeatures or [ ]) ++ [ "uid-range" ]);
          });
      };
  };
}
