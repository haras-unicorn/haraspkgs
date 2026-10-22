{ self, selfLib, ... }:

{
  self.flakeModules.benchmarks = {
    self = false;
    flake = true;
    value =
      { lib, config, ... }:
      {
        options.self.benchmarks = lib.mkOption {
          default = { };
          description = "Declarative container benchmark harnesses.";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                imports = [ (selfLib.lib.selfSubmodule (lib.types.functionTo lib.types.deferredModule)) ];

                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    defaultText = lib.literalMD "the attribute name";
                    description = "Benchmark name, used in the NixOS test name.";
                  };

                  machine = lib.mkOption {
                    type = lib.types.str;
                    description = "Machine whose systemd service journal is inspected.";
                  };

                  service = lib.mkOption {
                    type = lib.types.str;
                    description = "systemd service whose journal is inspected in the machine.";
                  };

                  marker = lib.mkOption {
                    type = lib.types.str;
                    description = "Literal marker to wait for in the service journal.";
                  };

                  timeout = lib.mkOption {
                    type = lib.types.int;
                    default = 3600;
                    description = "Timeout in seconds for the benchmark and its journal wait.";
                  };
                };
              }
            )
          );
        };

        config = {
          self.lib.benchmarks =
            lib.genAttrs (builtins.filter (system: lib.hasSuffix "linux" system) config.systems)
              (
                system:
                builtins.mapAttrs (
                  _: benchmark: args:
                  (config.self.lib.${system}.pkgs.extend self.overlays.benchmarks)
                  .${selfLib.overlays.namespace}.makeBenchmark
                    (benchmark // { inherit args; })
                ) config.self.benchmarks
              );
        };
      };
  };
}
