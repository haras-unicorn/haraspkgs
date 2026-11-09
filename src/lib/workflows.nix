{ lib, ... }:

{
  self.lib.workflows = {
    render =
      name: workflow:
      let
        jobName = workflow.jobName or "build";

        matrix = workflow.matrix or null;

        cachix = workflow.cachix or null;

        installable = workflow.installable or null;

        installNixStep = lib.optional (workflow.installNix or true) {
          uses = "cachix/install-nix-action@v31";
          "with".extra_nix_config = workflow.installNixExtraConfig or "";
        };

        cachixStep = lib.optional (cachix != null) {
          uses = "cachix/cachix-action@v15";
          "with" = lib.filterAttrs (_: value: value != null) {
            inherit (cachix) name;
            extraPullNames = cachix.extraPullNames or null;
            authToken = cachix.authToken or null;
          };
        };

        # Builds that need uid-range run VMs and containers, which need these
        # two settings on the runner. The user namespace setting only exists
        # on runners with the Ubuntu AppArmor restriction.
        runnerSteps = lib.optionals (workflow.installNix or true) [
          {
            name = "Enable KVM";
            "if" = "runner.os == 'Linux'";
            run = ''
              echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' | sudo tee /etc/udev/rules.d/99-kvm4all.rules
              sudo udevadm control --reload-rules
              sudo udevadm trigger --name-match=kvm
            '';
          }
          {
            name = "Allow unprivileged user namespaces";
            "if" = "runner.os == 'Linux'";
            run = ''
              if [ -e /proc/sys/kernel/apparmor_restrict_unprivileged_userns ]; then
                sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
              fi
            '';
          }
        ];

        installableStep = lib.optional (installable != null) {
          run = "nix build --show-trace ${installable}";
        };

        baseSteps = [
          {
            uses = "actions/checkout@v4";
            "with".fetch-depth = 0;
          }
        ]
        ++ installNixStep
        ++ cachixStep
        ++ runnerSteps
        ++ installableStep
        ++ (workflow.steps or [ ]);

        baseJob = {
          "runs-on" =
            if matrix != null && matrix ? os then "\${{ matrix.os }}" else workflow.runsOn or "ubuntu-latest";
          steps = baseSteps;
        }
        // lib.optionalAttrs (matrix != null) {
          strategy.matrix = matrix;
        };

        rendered = {
          name = workflow.name or name;
          on = workflow.on or { };
          permissions = lib.recursiveUpdate { contents = "read"; } (workflow.permissions or { });
          jobs = lib.recursiveUpdate { ${jobName} = baseJob; } (workflow.jobs or { });
        }
        // lib.optionalAttrs ((workflow.env or { }) != { }) {
          env = workflow.env;
        };
      in
      lib.generators.toYAML { } rendered + "\n";
  };
}
