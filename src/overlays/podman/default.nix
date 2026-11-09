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
              ''
            );
      in
      {
        makePodmanScript =
          {
            name,
            text,
            runtimeInputs ? [ ],
            startTimeout ? defaultStartTimeout,
            cuda ? defaultCuda,
          }:
          let
            sandbox = makeSandbox { inherit cuda; };
          in
          final.writeShellApplication {
            inherit name;
            runtimeInputs = runtimeInputs ++ sandbox.inputs;
            text = ''
              export PODMAN_SANDBOX_START_TIMEOUT=${builtins.toString startTimeout}
              # shellcheck source=/dev/null
              source ${sandbox.file}
              startPodmanSandbox
              trap stopPodmanSandbox EXIT
              ${text}
            '';
          };

        withPodman =
          derivation:
          derivation.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ hook ];
            requiredSystemFeatures = final.lib.unique ((old.requiredSystemFeatures or [ ]) ++ [ "uid-range" ]);
          });
      };
  };
}
