{ selfLib, ... }:

{
  self.overlays.overlays.benchmarks = {
    flake = true;
    value = final: prev: {
      makeBenchmark =
        {
          name,
          value,
          machine,
          service,
          marker,
          timeout,
          args,
          ...
        }:
        final.testers.runNixOSTest {
          name = "benchmark-${name}";
          globalTimeout = timeout;

          imports = [ (value args) ] ++ final.lib.optional final.config.cudaSupport selfLib.cuda.testModule;

          defaults = {
            _file = ./benchmarks.nix;
            key = ./benchmarks.nix;

            imports = final.lib.optional final.config.cudaSupport selfLib.cuda.guestModule;

            system.stateVersion = final.lib.mkDefault "26.05";
          };

          testScript = ''
            import shlex

            start_all()

            service = ${builtins.toJSON service}
            marker = ${builtins.toJSON marker}
            command = (
              "journalctl -u " + shlex.quote(service)
              + " --no-pager -o cat | grep -F -- " + shlex.quote(marker)
            )

            ${machine}.wait_until_succeeds(command, timeout=${builtins.toString timeout})
            line = ${machine}.succeed(command).splitlines()[0]
            (driver.out_dir / "benchmark.txt").write_text(line + "\n")
            print(line)
          '';
        };
    };
  };
}
