{ selfLib, ... }:

{
  self.overlays.overlays.containers = {
    flake = true;
    value = final: prev: {
      makeContainer =
        {
          name,
          value,
          specialArgs,
          args,
          ...
        }:
        let
          nixosSystem =
            args:
            import (final.path + "/nixos/lib/eval-config.nix") (
              {
                lib = final.lib;
                system = final.stdenv.hostPlatform.system;
              }
              // args
            );

          build = nixosSystem {
            inherit specialArgs;
            system = final.stdenv.hostPlatform.system;
            modules = [
              ({ lib, ... }: {
                _file = ./containers.nix;
                key = ./containers.nix;

                imports = [
                  selfLib.containers.nspawnModule
                  (value args)
                ]
                ++ final.lib.optional final.config.cudaSupport selfLib.cuda.guestModule;

                boot.isContainer = true;

                networking.hostName = "container-${name}";
                networking.firewall.enable = false;

                system.stateVersion = lib.mkDefault "26.05";
              })
            ];
          };
        in
        build.config.system.build.toplevel
        // {
          nspawn = build.config.system.build.nspawn;
        };
    };
  };
}
