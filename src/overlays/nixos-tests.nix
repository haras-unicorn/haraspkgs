{ selfLib, ... }:

{
  self.overlays.overlays.nixos-tests = {
    flake = true;
    value = final: prev: {
      makeNixosTest =
        {
          name,
          value,
          ...
        }:
        final.testers.runNixOSTest {
          name = "nixos-test-${name}";

          imports = [ value ] ++ final.lib.optional final.config.cudaSupport selfLib.cuda.testModule;

          defaults = {
            _file = ./nixos-tests.nix;
            key = ./nixos-tests.nix;

            imports = final.lib.optional (final.config.cudaSupport or false) selfLib.cuda.guestModule;

            system.stateVersion = final.lib.mkDefault "26.05";
          };
        };
    };
  };
}
